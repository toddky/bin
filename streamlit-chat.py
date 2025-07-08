#!/usr/bin/env streamlit-run
# vim: ft=python noet ts=4 sw=0 sts
#
import streamlit as st
import random
import string

def generate_gibberish():
	length = random.randint(50, 200)
	chars = string.ascii_letters + string.punctuation + ' ' * 10
	return ''.join(random.choice(chars) for _ in range(length))

st.title("Gibberish Chat")

# Initialize chat history
if "messages" not in st.session_state:
	st.session_state.messages = []

# Display chat messages
for message in st.session_state.messages:
	with st.chat_message(message["role"]):
		st.write(message["content"])

# User input
if prompt := st.chat_input("Say something..."):

	# Add user message to chat history
	st.session_state.messages.append({"role": "user", "content": prompt})

	# Display user message
	with st.chat_message("user"):
		st.write(prompt)

	response = generate_gibberish()
	with st.chat_message("bot"):
		st.write(response)
	st.session_state.messages.append({"role": "bot", "content": response})

