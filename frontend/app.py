from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, DataTable, Label, Input, Button
from textual.binding import Binding
from textual.screen import ModalScreen
from textual import events
import httpx
import asyncio
import os
import json
import websockets
from dotenv import load_dotenv

BASE_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000/ws"
load_dotenv()
API_KEY = os.getenv("API_KEY")

HEADERS = {
    "x-api-key": "Aaloo",
    "Content-Type": "application/json"
}


class CreateFlagModal(ModalScreen):
    """Modal screen for creating a new flag"""

    def compose(self) -> ComposeResult:
        yield Label("Create New Flag", id="modal-title")
        yield Input(placeholder="Flag name (e.g. dark_mode)", id="flag-name")
        yield Input(
            placeholder="Environment (development/production)",
            id="flag-env",
            value="development"
        )
        yield Label("Rule Type:")
        yield Input(
            placeholder="everyone / beta_only / percentage",
            id="flag-rule-type",
            value="everyone"
        )
        yield Input(
            placeholder="Rule value (leave empty for everyone)",
            id="flag-rule-value"
        )
        yield Button("Create", variant="success", id="create-btn")
        yield Button("Cancel", variant="error", id="cancel-btn")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel-btn":
            self.dismiss(None)
            return

        name = self.query_one("#flag-name", Input).value.strip()
        env = self.query_one("#flag-env", Input).value.strip()
        rule_type = self.query_one("#flag-rule-type", Input).value.strip()
        rule_value_raw = self.query_one("#flag-rule-value", Input).value.strip()

        # Parse rule_value based on rule_type
        if rule_type == "everyone":
            rule_value = None
        elif rule_type == "beta_only":
            rule_value = [u.strip() for u in rule_value_raw.split(",") if u.strip()]
        elif rule_type == "percentage":
            try:
                rule_value = int(rule_value_raw)
            except ValueError:
                rule_value = 10
        else:
            rule_value = None

        if name:
            self.dismiss({
                "name": name,
                "enabled": False,
                "environment": env or "development",
                "rule_type": rule_type or "everyone",
                "rule_value": rule_value
            })
        else:
            self.dismiss(None)


class DeleteConfirmModal(ModalScreen):
    """Modal screen for confirming flag deletion"""

    def __init__(self, flag_name: str):
        super().__init__()
        self.flag_name = flag_name

    def compose(self) -> ComposeResult:
        yield Label(f"Delete '{self.flag_name}'?", id="modal-title")
        yield Label("This cannot be undone.")
        yield Button("Delete", variant="error", id="confirm-btn")
        yield Button("Cancel", variant="primary", id="cancel-btn")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "confirm-btn":
            self.dismiss(True)
        else:
            self.dismiss(False)



class FeatureFlagApp(App):
    """Feature Flag Manager TUI"""

    CSS = """
    Screen {
        align: center middle;
    }

    ModalScreen {
        align: center middle;
    }

    ModalScreen > * {
        width: 60;
        background: $surface;
        padding: 2 4;
        border: thick $primary;
    }

    #modal-title {
        text-style: bold;
        color: $accent;
        margin-bottom: 1;
    }

    Input {
        margin-bottom: 1;
    }

    Button {
        margin: 1 1;
    }

    DataTable {
        height: 100%;
    }
    """

    TITLE = "🚩 Feature Flag Manager"

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("space", "toggle_flag", "Toggle"),
        Binding("n", "new_flag", "New Flag"),
        Binding("d", "delete_flag", "Delete"),
        Binding("r", "refresh", "Refresh"),
        Binding("a", "archive_flag", "Archive/Restore"),
    ]

    def __init__(self):
        super().__init__()
        self.flags = {}  # dict: {name: flag_data}
        self.ws_task = None

    def compose(self) -> ComposeResult:
        yield Header()
        yield DataTable()
        yield Footer()

    async def on_mount(self) -> None:
        
        table = self.query_one(DataTable)
        table.cursor_type = "row"
        table.add_columns(
            "Name", "Status", "Environment", "Rule", "Rule Value", "Archived"
        )
        await self.load_flags()
        
        self.ws_task = asyncio.create_task(self.listen_websocket())

    
    async def load_flags(self) -> None:
        """Load ALL flags (active + archived) into one view"""
        try:
            async with httpx.AsyncClient() as client:
                active_resp = await client.get(f"{BASE_URL}/flags")
                archived_resp = await client.get(f"{BASE_URL}/flags/archived")
            active_list = active_resp.json()
            archived_list = archived_resp.json()
            all_flags = active_list + archived_list
            self.flags = {f["name"]: f for f in all_flags}
            self.refresh_table()
        except Exception as e:
            self.notify(f"Error loading flags: {e}", severity="error")


    def refresh_table(self) -> None:
        
        table = self.query_one(DataTable)
        table.clear()

        for flag in self.flags.values():
            status = "ON  ✅" if flag["enabled"] else "OFF ❌"
            rule_type = flag["rule_type"]
            rule_value = str(flag["rule_value"]) if flag["rule_value"] else "-"
            archived = "📦 YES" if flag.get("archived", False) else "—"

            table.add_row(
                flag["name"],
                status,
                flag["environment"],
                rule_type,
                rule_value,
                archived,
                key=flag["name"]
            )

    
    async def listen_websocket(self) -> None:
        """Connect to WebSocket and listen for flag changes"""
        while True:
            try:
                async with websockets.connect(WS_URL) as ws:
                    self.notify("🟢 Connected to server", timeout=2)
                    async for message in ws:
                        data = json.loads(message)
                        self.handle_ws_message(data)
            except Exception as e:
                self.notify(
                    "🔴 WS disconnected — reconnecting in 3s...",
                    severity="warning",
                    timeout=3
                )
                await asyncio.sleep(3)

    def handle_ws_message(self, data: dict) -> None:
        
        msg_type = data.get("type")

        if msg_type == "flag_updated":
            flag = data["flag"]
            self.flags[flag["name"]] = flag
            self.refresh_table()
            self.notify(
                f"🔄 '{flag['name']}' → {'ON' if flag['enabled'] else 'OFF'}",
                timeout=2
            )

        elif msg_type == "flag_created":
            flag = data["flag"]
            self.flags[flag["name"]] = flag
            self.refresh_table()
            self.notify(f"✅ Flag '{flag['name']}' created", timeout=2)

        elif msg_type == "flag_deleted":
            name = data["flag_name"]
            self.flags.pop(name, None)
            self.refresh_table()
            self.notify(f"🗑️ Flag '{name}' deleted", timeout=2)

        elif msg_type == "flag_archived":
            flag = data["flag"]
            name = flag["name"]
            is_archived = flag.get("archived", False)
            self.flags[name] = flag
            self.refresh_table()
            if is_archived:
                self.notify(f"📦 '{name}' archived", timeout=2)
            else:
                self.notify(f"♻️ '{name}' restored", timeout=2)

    def action_quit(self) -> None:
        if self.ws_task:
            self.ws_task.cancel()
        self.exit()

    async def action_refresh(self) -> None:
        await self.load_flags()
        self.notify("🔄 Refreshed!", timeout=1)

    async def action_archive_flag(self) -> None:
        """a key — archive/unarchive selected flag"""
        table = self.query_one(DataTable)
        if not table.rows:
            return
        row = table.cursor_row
        flag_name = table.get_cell_at((row, 0))

        try:
            async with httpx.AsyncClient() as client:
                response = await client.patch(
                    f"{BASE_URL}/flags/{flag_name}/archive",
                    headers=HEADERS
                )
            if response.status_code == 200:
                updated = response.json()
                self.flags[flag_name] = updated
                self.refresh_table()
                if updated["archived"]:
                    self.notify(f"📦 Archived '{flag_name}'", timeout=2)
                else:
                    self.notify(f"♻️ Restored '{flag_name}'", timeout=2)
            else:
                self.notify("Archive failed!", severity="error")
        except Exception as e:
            self.notify(f"Error: {e}", severity="error")

    
    async def action_toggle_flag(self) -> None:
        """Space key — toggle selected flag"""
        table = self.query_one(DataTable)
        if not table.rows:
            return
        row = table.cursor_row
        flag_name = table.get_cell_at((row, 0))

        try:
            async with httpx.AsyncClient() as client:
                response = await client.patch(
                    f"{BASE_URL}/flags/{flag_name}/toggle"
                )
            if response.status_code == 200:
                updated = response.json()
                self.flags[flag_name] = updated
                self.refresh_table()
                status = "ON" if updated["enabled"] else "OFF"
                self.notify(f"Toggled '{flag_name}' → {status}", timeout=2)
            else:
                self.notify("Toggle failed!", severity="error")
        except Exception as e:
            self.notify(f"Error: {e}", severity="error")

    def action_new_flag(self) -> None:
        def handle_result(result):
            if result is None:
                return
            async def do_create():
                try:
                    async with httpx.AsyncClient() as client:
                        response = await client.post(
                            f"{BASE_URL}/flags",
                            json=result,
                            headers=HEADERS
                        )
                        if response.status_code == 200:
                            new_flag = response.json()
                            self.flags[new_flag["name"]] = new_flag
                            self.refresh_table()
                            self.notify(
                                f"✅ Created '{new_flag['name']}'", timeout=2)
                        elif response.status_code == 409:
                            self.notify(
                                "Flag already exists!", severity="error")
                        else:
                            self.notify("Failed to create flag!", severity="error")
                except Exception as e:
                    self.notify(f"Error: {e}", severity="error")
            asyncio.create_task(do_create())
        self.push_screen(CreateFlagModal(), handle_result)

    def action_delete_flag(self) -> None:
        table = self.query_one(DataTable)
        if not table.rows:
            return
        row = table.cursor_row
        flag_name = table.get_cell_at((row, 0))

        def handle_result(confirmed):
            if not confirmed:
                return
            async def do_delete():
                try:
                    async with httpx.AsyncClient() as client:
                        response = await client.delete(
                            f"{BASE_URL}/flags/{flag_name}",
                            headers=HEADERS
                        )
                    if response.status_code == 200:
                        self.flags.pop(flag_name, None)
                        self.refresh_table()
                        self.notify(
                            f"🗑️ Deleted '{flag_name}'", timeout=2)
                    else:
                        self.notify("Delete failed!", severity="error")
                except Exception as e:
                    self.notify(f"Error: {e}", severity="error")
            asyncio.create_task(do_delete())    
        self.push_screen(DeleteConfirmModal(flag_name), handle_result)


if __name__ == "__main__":
    app = FeatureFlagApp()
    app.run()