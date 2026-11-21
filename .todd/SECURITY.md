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

## SEC-B: Checks at a shared boundary

### SEC-B1: Gate Every Path Across The Same Boundary
A violation is a security check (secret scan, outbound address guard, authorization check, allowlist, or size cap) placed in one caller of an outbound or storage boundary while a sibling caller that reaches the same boundary omits it. The rule is followed when the check runs inside the shared boundary function that performs the send or write, or every path through the boundary calls the same gate helper. Code with a single path follows the rule. Why: a secret scan on the tool-call path does nothing when an agent can send the same payload through the sibling HTTP-target path on the same gateway.

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
