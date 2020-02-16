import json
from http.server import HTTPServer, BaseHTTPRequestHandler

import discord

WEBHOOK_URL = ""  # Your Discord Webhook URL here.

webhook = discord.Webhook.from_url(url=WEBHOOK_URL, adapter=discord.RequestsWebhookAdapter())


class ProxyHandler(BaseHTTPRequestHandler):
    def response(self, code):
        self.send_response(code)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_POST(self):
        try:
            data = json.loads(self.rfile.read(int(self.headers['Content-Length'])).decode("utf-8"))
        except json.JSONDecodeError:
            self.response(400)
            return

        if "type" not in data:
            self.response(400)
            return

        embed: discord.Embed = discord.Embed(color=0xEE82EE)

        if data["type"] == "jump":
            if "jump" not in data or "name" not in data:
                self.response(400)
                return

            try:
                from_x: int = int(data["jump"][0])
                from_y: int = int(data["jump"][1])
                from_z: int = int(data["jump"][2])

                to_x: int = int(data["jump"][3])
                to_y: int = int(data["jump"][4])
                to_z: int = int(data["jump"][5])

                hyper: bool = data["jump"][6]
            except (ValueError, IndexError):
                self.response(400)
                return

            embed.set_author(name="%s has jumped %s" % (data["name"], "hyper" if hyper else ""), icon_url="")
            embed.add_field(name="From", value="X: **%s** Y: **%s** Z: **%s**" % (from_x, from_y, from_z), inline=True)
            embed.add_field(name="To", value="X: **%s** Y: **%s** Z: **%s**" % (to_x, to_y, to_z), inline=True)
            embed.add_field(name="Movement",
                            value="X: **%s** Y: **%s** Z: **%s**" % (to_x - from_x, to_y - from_y, to_z - from_z),
                            inline=False)
        elif data["type"] == "radarScan":
            if "results" not in data:
                self.response(400)
                return

            embed.set_author(name="Warp Radar has scanned", icon_url="")
            embed.add_field(name="%s results" % len(data["results"]), value="\n".join(data["results"]))
        else:
            self.response(400)
            return

        webhook.send(embed=embed, username="Interstellar2", avatar_url="https://raw.githubusercontent.com/LemADEC"
                                                                       "/WarpDrive/MC1.12/src/main"
                                                                       "/resources/assets/warpdrive/textures/blocks"
                                                                       "/movement/ship_core"
                                                                       "-right_online.png")

        self.response(200)


server_address = ('', 4248)
httpd = HTTPServer(server_address, ProxyHandler)
print("Starting server...")
httpd.serve_forever()
