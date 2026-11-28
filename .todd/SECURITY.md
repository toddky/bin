# Security Rules For Services With Users

Read this file when the code is a service that has users, accounts, roles, or rooms, or when you do a security audit of one. The security rules that apply to any program, including a single script, are in CODE_REVIEW.md under CR-I.

Rules are grouped by letter:

| Section | Covers |
|---|---|
| SEC-A | Who the caller is and what they may do |
| SEC-B | Checks at a shared boundary |

Each rule has the same shape as the rules in CODE_REVIEW.md. The first sentence says exactly what counts as a violation. The second says when the rule is followed, including when the code has nothing the rule applies to. Then comes why, and the Bad and Good examples. The examples are Python 3.9 or newer, and each pair was run to show what the rule claims.

## SEC-A: Who the caller is and what they may do

### SEC-A1: Ownership Comes From The Account Binding
A violation is an ownership check that passes because the caller created a record with the same name as the protected thing, such as a saved profile, draft, or alias, when any user may create such a record under any name. The rule is followed when ownership is read from the one binding the system itself controls, such as the name's registration to an account id, and creating a record under a name another account holds is refused. Code where users do not choose names follows the rule. Why: any user saves a profile named after someone else's agent, and every "owner only" action on that agent (read its activity, remove it, rename it) now accepts them.

Bad:
```python
def owns_agent(caller, agent_name):
    if name_owner(agent_name) == caller.account_id:
        return True
    return any(
        profile.name == agent_name and profile.owner == caller.name
        for profile in saved_profiles()
    )
```

Good:
```python
def owns_agent(caller, agent_name):
    return name_owner(agent_name) == caller.account_id
```

### SEC-A2: Check The Named User Against The Caller
A violation is a handler that takes the user to act as, or to read for, from the request body or query and uses it without checking that the authenticated caller holds that name. The rule is followed when the handler takes the user from the authenticated identity, or passes the named user through the same "may the caller act as this name" check that write commands use, and validates its type and length. A handler open only to administrators follows the rule. Why: any reader of a room sends another user's name with "mark as read" and overwrites that user's cursor, or sends a megabyte of text as the name and the server stores it as a key.

Bad:
```python
def mark_digest_read(caller, room, body):
    room.cursors[body["user"]] = room.seq
    save(room)
```

Good:
```python
def mark_digest_read(caller, room, body):
    user = body["user"]
    if not caller.holds(user):
        raise Forbidden(f"mark digest read: caller {caller.name} does not hold the name {user!r}")
    room.cursors[user] = room.seq
    save(room)
```

### SEC-A3: Access Checks Read Live Membership
A violation is an access check that reads a role, token, or flag from a membership record without first confirming the record is still active, when removing or leaving marks the record instead of deleting it. The rule is followed when the check goes through one helper that returns nothing for a left or removed member, and removal clears the role and every other grant on the record. A store that deletes the record on removal follows the rule. Why: an admin removed from a private room still reads as "admin" on a path that checks only the role, and uses it to pull the room into a project they own and read it again.

Bad:
```python
def require_admin(room, caller):
    if room.members[caller.name].role != "admin":
        raise Forbidden(f"{caller.name} is not an admin of room {room.name}")
```

Good:
```python
def require_admin(room, caller):
    member = active_member(room, caller.name)
    if member is None or member.role != "admin":
        raise Forbidden(f"{caller.name} is not an admin of room {room.name}")
```

### SEC-A4: Saved Automation Runs As Its Owner
A violation is user-defined automation (a flow, rule, webhook, scheduled job, or macro) whose steps read or change data with the system's authority instead of the authority of the user who saved it. That includes a trigger that hands the owner every matching object without a visibility check, an authorization check that is skipped when the caller has no identity, and an approval step whose default approver is the automation's owner. The rule is followed when each trigger payload and each step is checked against the owner's access exactly as a direct request from the owner would be, a caller with no identity is refused, and an approver must be someone other than the owner. Automation only administrators can define follows the rule. Why: a member saves a flow that triggers on every task change, then reads every task on the system, edits tasks they cannot open, and posts into rooms they are not in.

Bad:
```python
def run_step(flow, step):
    if step.kind == "update_task":
        tasks.update(step.task_id, step.changes, actor="system")
```

Good:
```python
def run_step(flow, step):
    if step.kind == "update_task":
        task = tasks.get(step.task_id)
        if not tasks.can_change(task, flow.owner):
            raise Forbidden(f"flow owner {flow.owner} may not change task {step.task_id}")
        tasks.update(step.task_id, step.changes, actor=flow.owner)
```

### SEC-A5: Audit Records Name The Verified Identity
A violation is an audit or security log entry whose actor comes from something the caller sent, such as a request header, a form field, or a name in the message body, rather than from the identity the server verified. The rule is followed when the actor field holds the authenticated identity, and anything the caller claimed goes in a separate field marked as claimed. Why: whoever controls the actor field can put someone else's name on their own actions, and the log meant to find them points at the victim.

Bad:
```python
def audit_refusal(request, session, reason):
    audit_log.write(actor=request.headers.get("X-Acting-As", session.user), action="refused", reason=reason)
```

Good:
```python
def audit_refusal(request, session, reason):
    audit_log.write(
        actor=session.user,
        claimed_actor=request.headers.get("X-Acting-As"),
        action="refused",
        reason=reason,
    )
```

### SEC-A6: Revoking Needs Only Proof Of Ownership
A violation is a path that removes access, such as revoke, disable, sign out, or kill, that requires something only the granting path needs, such as a display label in the token, a successful audit write, a reachable dependency, or a rate-limit slot. The rule is followed when the revoke path checks only that the caller owns what is revoked, a later step that fails is logged with the id of what was revoked and does not undo it or report failure, and a test revokes with each grant-only precondition missing. Why: the moment someone needs to revoke is often the moment something else is broken, such as a stolen key during an audit outage, and a revoke that refuses then leaves the attacker in.

Bad:
```python
def revoke_key(caller, key_id):
    key = keys.get(key_id)
    if key is None or key.owner != caller.account_id or not caller.display_name:
        raise Forbidden(f"revoke {key_id}: caller {caller.account_id} may not revoke it")
    audit.write("revoke", key_id, actor=caller.account_id)
    keys.revoke(key_id)
```

Good:
```python
def revoke_key(caller, key_id):
    key = keys.get(key_id)
    if key is None or key.owner != caller.account_id:
        raise Forbidden(f"revoke {key_id}: caller {caller.account_id} does not own it")
    keys.revoke(key_id)
    try:
        audit.write("revoke", key_id, actor=caller.account_id)
    except AuditUnavailable as error:
        log.error("revoked key %s but the audit write failed: %s", key_id, error)
```

### SEC-A7: Copied Data Keeps Its Source's Label
A violation is copying data from a labelled or access-controlled source, such as a ticket, a private room, or a file, into a container with weaker access, such as a channel, a task, or a cache, and then serving the copy under the container's access alone. The rule is followed when the copy carries its source's label, every read path compares that label with the reader's access, and a test reads the copy as a container member who could not read the source. Why: each piece of data stays within its own access, but a copy inherits the access of wherever it lands, which is usually wider.

Bad:
```python
def copy_ticket_to_task(ticket, task):
    task.attachments.append(ticket.body)

def read_task(caller, task):
    require_member(task.channel, caller)
    return task.attachments
```

Good:
```python
def copy_ticket_to_task(ticket, task):
    task.attachments.append(Attachment(body=ticket.body, label=ticket.label))

def read_task(caller, task):
    require_member(task.channel, caller)
    return [item.body for item in task.attachments if caller.may_read(item.label)]
```

### SEC-A8: Show The Whole Thing A Person Approves
A violation is an approval prompt that shows a person a summary, a truncated copy, or the requester's own description of an action, while the approval authorizes the full action, such as a hash of the whole request body. The rule is followed when the prompt shows every field the approval binds, after redaction but without truncation, or the request is refused when it is too long to show. Why: whoever builds the request chooses what falls past the cut, so the person approves text they never saw.

Bad:
```python
def approval_card(call):
    text = json.dumps(redact(call.arguments), sort_keys=True)
    return {"text": text[:500], "approves": sha256(call)}
```

Good:
```python
# The longest body the approval card can show.
MAX_CARD_CHARS = 500

def approval_card(call):
    text = json.dumps(redact(call.arguments), sort_keys=True)
    if len(text) > MAX_CARD_CHARS:
        raise TooLongToApprove(f"approve {call.name}: {len(text)} characters won't fit the card's {MAX_CARD_CHARS}; split it")
    return {"text": text, "approves": sha256(call)}
```

## SEC-B: Checks at a shared boundary

### SEC-B1: Gate Every Path Across The Same Boundary
A violation is a security check (secret scan, outbound address guard, authorization check, allowlist, or size cap) placed in one caller of an outbound or storage boundary while a sibling caller that reaches the same boundary omits it. The rule is followed when the check runs inside the shared boundary function that performs the send or write, or every path through the boundary calls the same gate helper. Code with a single path follows the rule. Why: a secret scan on the tool-call path does nothing when an agent can send the same payload through the sibling HTTP-target path on the same gateway.

The same holds for a check keyed on an optional request field, such as a per-request room check that a cross-room query passes by sending no room. Apply the check in the code that collects the data or performs the action, for every kind of caller, and test the new path as each kind of caller with an allow-list narrower than what exists. Why: a check keyed on an optional field passes whenever the field is missing, and the new path looks covered in review because the old check sits nearby.

Bad:
```python
def tool_call(request):
    if find_secrets(request.body):
        raise SecretDetected(f"tool call to {request.target}: the body holds a secret")
    return send_http(request.target, request.body)

def target_call(request):
    return send_http(request.target, request.body)

def send_http(target, body):
    return do_request(target, body)
```

Good:
```python
def tool_call(request):
    return send_http(request.target, request.body)

def target_call(request):
    return send_http(request.target, request.body)

def send_http(target, body):
    if find_secrets(body):
        raise SecretDetected(f"send to {target}: the body holds a secret")
    return do_request(target, body)
```

### SEC-B2: Forward Headers By Allowlist
A violation is a proxy or relay that copies every incoming request header to its upstream except a fixed list of names. The rule is followed when the proxy forwards only the headers the upstream needs, named in an allowlist, or strips whole prefixes that carry trust (such as the edge's identity and token headers) before forwarding. A proxy whose upstream is in the same trust zone as the proxy's own caller follows the rule. Why: the edge adds a shared trust token to every request, the relay passes it on in clear, and anyone who can read the upstream's traffic or logs can then forge any user at the front door.

Bad:
```python
def upstream_headers(request_headers):
    return {
        name: value
        for name, value in request_headers.items()
        if name.lower() not in {"authorization", "cookie"}
    }
```

Good:
```python
FORWARDED_HEADERS = ("Connection", "Sec-WebSocket-Key", "Sec-WebSocket-Protocol", "Sec-WebSocket-Version", "Upgrade")

def upstream_headers(request_headers):
    return {
        name: request_headers[name]
        for name in FORWARDED_HEADERS
        if name in request_headers
    }
```

### SEC-B3: State Changes Never Answer GET
A violation is an HTTP endpoint that changes state, such as creating, revoking, or deleting something, and answers a GET request. The rule is followed when such an endpoint accepts only POST, PUT, PATCH, or DELETE, refuses GET with 405, and a test sends GET and expects the refusal. Why: browsers, link previews, crawlers, and prefetchers send GET without asking, and another site can trigger one with an image tag, so the change runs without anyone meaning it.

Bad:
```python
ROUTES = {
    "/keys": {"GET": list_keys},
    "/keys/revoke": {"GET": revoke_key, "POST": revoke_key},
}
```

Good:
```python
ROUTES = {
    "/keys": {"GET": list_keys},
    "/keys/revoke": {"POST": revoke_key},
}
```
