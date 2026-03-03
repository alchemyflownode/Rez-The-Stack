import tkinter as tk
import threading
import requests
import keyboard
import pyperclip

KERNEL_URL = "http://localhost:3001/api/kernel"
HOTKEY = "ctrl+shift+space"

class RezOrb:
    def __init__(self):
        self.root = tk.Tk()
        self.root.overrideredirect(True)
        self.root.attributes('-topmost', True)
        self.root.attributes('-alpha', 0.95)
        self.root.configure(bg='#0a0a1a')
        sw = self.root.winfo_screenwidth()
        self.root.geometry(f"400x180+{sw-420}+20")
        
        self.frame = tk.Frame(self.root, bg='#1a1a2e', padx=20, pady=15)
        self.frame.pack(fill=tk.BOTH, expand=True)
        
        tk.Label(self.frame, text="🦊 REZ COPILOT", fg='#FFD700', bg='#1a1a2e', font=("Segoe UI", 12, "bold")).pack(anchor='w')
        self.status_label = tk.Label(self.frame, text="Ready.", fg='#00B4D8', bg='#1a1a2e', font=("Segoe UI", 10))
        self.status_label.pack(anchor='w', pady=(10,5))
        self.response_label = tk.Label(self.frame, text="", fg='#E5E7EB', bg='#1a1a2e', font=("Segoe UI", 9), wraplength=360, justify=tk.LEFT)
        self.response_label.pack(fill=tk.BOTH, expand=True)

        self.visible = False
        self.root.withdraw()
        keyboard.add_hotkey(HOTKEY, self.toggle)
        print(f"🦊 RezCopilot Active. Press {HOTKEY} to activate.")

    def toggle(self):
        if self.visible:
            self.root.withdraw()
            self.visible = False
        else:
            self.root.deiconify()
            self.visible = True
            self.process_clipboard()

    def process_clipboard(self):
        self.status_label.config(text="Thinking...")
        query = pyperclip.paste()
        threading.Thread(target=self.query, args=(query,), daemon=True).start()

    def query(self, query):
        try:
            r = requests.post(KERNEL_URL, json={"task": query}, timeout=30)
            d = r.json()
            res = d.get('content') or d.get('answer') or "Done."
            self.root.after(0, lambda r=res: self.update(r))
        except Exception as e:
            msg = str(e) # CAPTURE ERROR IMMEDIATELY
            self.root.after(0, lambda m=msg: self.update(f"Error: {m}"))

    def update(self, text):
        self.response_label.config(text=text[:200])
        pyperclip.copy(text)
        self.status_label.config(text="Result copied!")
        self.root.after(5000, lambda: self.root.withdraw())

    def run(self):
        self.root.mainloop()

if __name__ == "__main__":
    RezOrb().run()