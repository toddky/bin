#!/usr/bin/env python3

# ==============================================================================
# IMPORT
# ==============================================================================
import json
import os
import sys

from pathlib import Path
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.errors import HttpError


# ==============================================================================
# VARS
# ==============================================================================
SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']

XDG_CONFIG_HOME = Path.home() / '.config'
CONFIG_DIR = XDG_CONFIG_HOME / 'my-gmail'
TOKEN_FILE = CONFIG_DIR / 'token.json'
CREDENTIALS_FILE = CONFIG_DIR / 'credentials.json'


# ==============================================================================
# FUNCTIONS
# ==============================================================================
def error(message):
    print(f"ERROR: {message}", file=sys.stderr)


# ==============================================================================
# AUTHERROR
# ==============================================================================
class AuthError(Exception):
    pass


# ==============================================================================
# GMAIL
# ==============================================================================
class Gmail:
    def __init__(self, token_file=TOKEN_FILE, credentials_file=CREDENTIALS_FILE, scopes=SCOPES):
        self.token_file = Path(token_file)
        self.credentials_file = Path(credentials_file)
        self.scopes = scopes
        self.service = None

    def connect(self):
        try:
            creds = self._get_credentials()
            self.service = build('gmail', 'v1', credentials=creds)
            return self
        except AuthError as e:
            error(str(e))
            sys.exit(1)

    def _get_credentials(self):
        creds = self._load_credentials()
        
        if creds and creds.valid:
            return creds
            
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
                self._save_credentials(creds)
                return creds
            except Exception as e:
                error(f"Failed to refresh credentials: {e}")
                self.token_file.unlink(missing_ok=True)
                return self._get_credentials()

        if not self.credentials_file.exists():
            raise AuthError(
                "credentials.json not found. "
                "Please download credentials.json from Google Cloud Console."
            )

        try:
            flow = InstalledAppFlow.from_client_secrets_file(
                self.credentials_file, self.scopes)
            creds = flow.run_local_server(port=0)
            self._save_credentials(creds)
            return creds

        except Exception as e:
            raise AuthError(f"Authentication failed: {e}")

    def _load_credentials(self):
        if not self.token_file.exists():
            return None

        try:
            with self.token_file.open('r') as token:
                return Credentials.from_authorized_user_info(json.load(token))
        except json.JSONDecodeError:
            error("Invalid token file format. Recreating authentication.")
            self.token_file.unlink(missing_ok=True)
            return None
        except IOError as e:
            error(f"Could not read token file: {e}")
            return None

    def _save_credentials(self, creds):
        try:
            self.token_file.parent.mkdir(parents=True, exist_ok=True)
            with self.token_file.open('w') as token:
                token_data = {
                    'token': creds.token,
                    'refresh_token': creds.refresh_token,
                    'token_uri': creds.token_uri,
                    'client_id': creds.client_id,
                    'client_secret': creds.client_secret,
                    'scopes': creds.scopes
                }
                json.dump(token_data, token)
        except IOError as e:
            error(f"Failed to save credentials: {e}")

    def get_unread_count(self):
        if not self.service:
            self.connect()

        try:
            results = self.service.users().messages().list(
                userId='me',
                q='is:unread in:inbox'
            ).execute()
            messages = results.get('messages', [])
            if not messages:
                return 0

            # More accurate result if pagination is needed
            return results.get('resultSizeEstimate', len(messages))

        except HttpError as e:
            error(f"Gmail API error: {e}")
            return -1
        except Exception as e:
            error(f"Failed to fetch unread messages: {e}")
            return -1

