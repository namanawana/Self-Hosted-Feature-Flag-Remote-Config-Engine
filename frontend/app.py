from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, DataTable
from textual.binding import Binding
import httpx

BASE_URL = "http://localhost:8000"

class FeatureFlagApp(App):

    TITLE = "Feature Flag Manager"

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("space", "toggle_flag", "Toggle"),
        Binding("n", "new_flag", "New Flag"),
        Binding("d", "delete_flag", "Delete"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        yield DataTable()
        yield Footer()

    def on_mount(self) -> None:
        table = self.query_one(DataTable)
        table.add_columns("Name", "Status", "Environment", "Rule")
        self.load_flags()

    def load_flags(self) -> None:
        try:
            response = httpx.get(f"{BASE_URL}/flags")
            flags = response.json()

            table = self.query_one(DataTable)
            table.clear()

            for flag in flags:
                status = "ON ✅" if flag["enabled"] else "OFF ❌"
                rule = flag["rule_type"]
                table.add_row(
                    flag["name"],
                    status,
                    flag["environment"],
                    rule,
                    key=flag["name"]
                )
        except Exception as e:
            self.notify(f"Error loading flags: {e}", severity="error")

    def action_quit(self) -> None:
        self.exit()

    def action_toggle_flag(self) -> None:
        table = self.query_one(DataTable)
        row_key = table.cursor_row
        if row_key is None:
            return
        flag_name = table.get_cell_at((table.cursor_row, 0))

        try:
            response = httpx.patch(f"{BASE_URL}/flags/{flag_name}/toggle")
            if response.status_code == 200:
                self.notify(f"Toggled {flag_name}!")
                self.load_flags()  # refresh table
        except Exception as e:
            self.notify(f"Error: {e}", severity="error")

    def action_new_flag(self) -> None:
       
        self.notify("Create flag — coming next!")

    def action_delete_flag(self) -> None:
        """D key — will add delete confirmation later"""
        self.notify("Delete flag — coming next!")


if __name__ == "__main__":
    app = FeatureFlagApp()
    app.run()