import os
import re
import shutil

class HyprConfigParser:
    def __init__(self, config_dir=None):
        if config_dir is None:
            # Check current directory for 'hypr' folder first (for dev/workspace testing)
            local_path = os.path.abspath("./hypr")
            if os.path.exists(local_path) and os.path.isdir(local_path):
                self.config_dir = local_path
            else:
                self.config_dir = os.path.expanduser("~/.config/hypr")
        else:
            self.config_dir = config_dir
        
        self.modules_dir = os.path.join(self.config_dir, "modules")
        os.makedirs(self.modules_dir, exist_ok=True)
        print(f"[HyprConfigParser] Initialized with config_dir: {self.config_dir}")

    def get_module_path(self, filename):
        return os.path.join(self.modules_dir, filename)

    def backup_file(self, filepath):
        if os.path.exists(filepath):
            shutil.copy2(filepath, filepath + ".bak")

    def read_config_values(self, filename):
        """
        Returns a dictionary of all parsed values, with keys formatted as 'block.subblock.key'.
        E.g. {
            'general.gaps_in': '5',
            'decoration.rounding': '10',
            'decoration.blur.enabled': 'true'
        }
        """
        filepath = self.get_module_path(filename)
        if not os.path.exists(filepath):
            return {}

        with open(filepath, 'r') as f:
            lines = f.readlines()

        values = {}
        stack = []

        for line in lines:
            no_comment = line.split('#')[0]
            
            # Check block open/close
            open_match = re.search(r'([a-zA-Z0-9_\-]+)\s*\{', no_comment)
            close_match = '}' in no_comment

            # Parse key-val
            kv_match = re.match(r'^\s*([a-zA-Z0-9_\-\.]+)\s*=\s*([^#\n]+)', line)
            if kv_match:
                key = kv_match.group(1).strip()
                val = kv_match.group(2).strip()
                
                if stack:
                    full_key = ".".join(stack) + "." + key
                else:
                    full_key = key
                values[full_key] = val

            # Update stack
            if open_match:
                block_name = open_match.group(1)
                stack.append(block_name)
            elif close_match:
                if stack:
                    stack.pop()

        return values

    def update_key_value(self, filename, block_path, target_key, new_value):
        """
        Updates a key's value inside a specific block path in filename.
        Preserves formatting, whitespace, comments, and structure.
        """
        filepath = self.get_module_path(filename)
        if not os.path.exists(filepath):
            return False

        self.backup_file(filepath)

        with open(filepath, 'r') as f:
            lines = f.readlines()

        new_lines = []
        stack = []
        updated = False

        for line in lines:
            no_comment = line.split('#')[0]
            
            open_match = re.search(r'([a-zA-Z0-9_\-]+)\s*\{', no_comment)
            close_match = '}' in no_comment

            # Current state is evaluated *before* we push the new block to stack,
            # which is correct since block header itself has no key-values.
            is_target_block = (stack == block_path)

            kv_match = re.match(r'^(\s*)([a-zA-Z0-9_\-\.]+)\s*=\s*([^#\n]+)(.*)$', line)
            
            if is_target_block and kv_match and not updated:
                indent = kv_match.group(1)
                key = kv_match.group(2)
                val = kv_match.group(3).strip()
                comment = kv_match.group(4)
                
                if key == target_key:
                    # Construct replacement keeping indent and comments
                    new_line = f"{indent}{key} = {new_value}{comment}\n"
                    new_lines.append(new_line)
                    updated = True
                    
                    if open_match:
                        stack.append(open_match.group(1))
                    elif close_match:
                        if stack:
                            stack.pop()
                    continue

            # Update stack
            if open_match:
                stack.append(open_match.group(1))
            elif close_match:
                if stack:
                    stack.pop()

            new_lines.append(line)

        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        
        return updated

    # --- STARTUP APPS PARSER ---

    def read_startup_items(self):
        filepath = self.get_module_path("startup.conf")
        if not os.path.exists(filepath):
            return []

        with open(filepath, 'r') as f:
            lines = f.readlines()

        items = []
        for idx, line in enumerate(lines):
            match = re.match(r'^(\s*)(#?)\s*(exec-once|exec)\s*=\s*([^#\n]+)(.*)$', line)
            if match:
                indent = match.group(1)
                disabled = match.group(2) == "#"
                exec_type = match.group(3)
                command = match.group(4).strip()
                comment = match.group(5).strip()
                
                items.append({
                    "id": idx,
                    "type": exec_type,
                    "command": command,
                    "enabled": not disabled,
                    "comment": comment.lstrip('#').strip(),
                    "raw_line": line
                })
        return items

    def toggle_startup_item(self, item_id, enable):
        filepath = self.get_module_path("startup.conf")
        if not os.path.exists(filepath):
            return False

        self.backup_file(filepath)

        with open(filepath, 'r') as f:
            lines = f.readlines()

        if item_id < 0 or item_id >= len(lines):
            return False

        line = lines[item_id]
        match = re.match(r'^(\s*)(#?)\s*(exec-once|exec)\s*=\s*(.*)$', line)
        if match:
            indent = match.group(1)
            is_disabled = match.group(2) == "#"
            exec_type = match.group(3)
            rest = match.group(4)
            
            if enable and is_disabled:
                lines[item_id] = f"{indent}{exec_type} = {rest}\n"
            elif not enable and not is_disabled:
                lines[item_id] = f"{indent}# exec-once = {rest}\n" if exec_type == "exec-once" else f"{indent}# exec = {rest}\n"
                
            with open(filepath, 'w') as f:
                f.writelines(lines)
            return True
        return False

    def add_startup_item(self, exec_type, command, comment=""):
        filepath = self.get_module_path("startup.conf")
        self.backup_file(filepath)

        comment_str = f" # {comment}" if comment else ""
        new_line = f"{exec_type} = {command}{comment_str}\n"

        with open(filepath, 'a') as f:
            f.write(new_line)
        return True

    def delete_startup_item(self, item_id):
        filepath = self.get_module_path("startup.conf")
        if not os.path.exists(filepath):
            return False

        self.backup_file(filepath)

        with open(filepath, 'r') as f:
            lines = f.readlines()

        if item_id < 0 or item_id >= len(lines):
            return False

        del lines[item_id]

        with open(filepath, 'w') as f:
            f.writelines(lines)
        return True

    # --- KEYBINDINGS PARSER ---

    def parse_keybinding_line(self, line):
        # Remove comments first
        parts_comment = line.split('#', 1)
        code = parts_comment[0].strip()
        comment = parts_comment[1].strip() if len(parts_comment) > 1 else ""
        
        # Match bind[a-z]* = ...
        match = re.match(r'^\s*(bind[a-z]*)\s*=\s*(.*)$', code)
        if not match:
            return None
            
        bind_type = match.group(1)
        rest = match.group(2)
        
        # Split tokens by comma
        tokens = [t.strip() for t in rest.split(',')]
        
        # Extract mods, key, dispatcher, args
        mods = tokens[0] if len(tokens) > 0 else ""
        key = tokens[1] if len(tokens) > 1 else ""
        dispatcher = tokens[2] if len(tokens) > 2 else ""
        args = ",".join(tokens[3:]) if len(tokens) > 3 else ""
        
        if args == "" and dispatcher.endswith(','):
            dispatcher = dispatcher[:-1].strip()
            
        return {
            "type": bind_type,
            "mods": mods,
            "key": key,
            "dispatcher": dispatcher,
            "args": args.strip(),
            "comment": comment
        }

    def read_keybindings(self):
        filepath = self.get_module_path("keybinding.conf")
        if not os.path.exists(filepath):
            return []

        with open(filepath, 'r') as f:
            lines = f.readlines()

        binds = []
        for idx, line in enumerate(lines):
            parsed = self.parse_keybinding_line(line)
            if parsed:
                parsed["id"] = idx
                parsed["raw_line"] = line
                binds.append(parsed)
        return binds

    def update_keybinding(self, line_index, bind_type, mods, key, dispatcher, args, comment=""):
        filepath = self.get_module_path("keybinding.conf")
        if not os.path.exists(filepath):
            return False

        self.backup_file(filepath)

        with open(filepath, 'r') as f:
            lines = f.readlines()

        if line_index < 0 or line_index >= len(lines):
            return False

        comment_str = f" # {comment}" if comment else ""
        args_str = f", {args}" if args else ""
        new_line = f"{bind_type} = {mods}, {key}, {dispatcher}{args_str}{comment_str}\n"
        lines[line_index] = new_line

        with open(filepath, 'w') as f:
            f.writelines(lines)
        return True

    def delete_keybinding(self, line_index):
        filepath = self.get_module_path("keybinding.conf")
        if not os.path.exists(filepath):
            return False

        self.backup_file(filepath)

        with open(filepath, 'r') as f:
            lines = f.readlines()

        if line_index < 0 or line_index >= len(lines):
            return False

        del lines[line_index]

        with open(filepath, 'w') as f:
            f.writelines(lines)
        return True

    def add_keybinding(self, bind_type, mods, key, dispatcher, args, comment=""):
        filepath = self.get_module_path("keybinding.conf")
        self.backup_file(filepath)

        comment_str = f" # {comment}" if comment else ""
        args_str = f", {args}" if args else ""
        new_line = f"{bind_type} = {mods}, {key}, {dispatcher}{args_str}{comment_str}\n"

        with open(filepath, 'a') as f:
            f.write(new_line)
        return True
