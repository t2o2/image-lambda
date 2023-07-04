def handler(event, context):
    # expect {"name": "foo", "action": "bar"}
    name = event.get('name', 'forest')
    action = event.get('action', 'run')
    return f"Hello {name}, {action}!"
    