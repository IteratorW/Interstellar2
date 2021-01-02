import json
from http.server import HTTPServer, BaseHTTPRequestHandler
import matplotlib.cm
import discord
import random

WEBHOOK_URL = ""  # Your Discord Webhook URL here.

webhook = discord.Webhook.from_url(url=WEBHOOK_URL, adapter=discord.RequestsWebhookAdapter())


def get_color_for_string(s):
    cmap = matplotlib.cm.get_cmap('rainbow')

    random.seed(s)
    pos = random.uniform(0, 1)

    rgba = [int(x * 255) for x in cmap(pos)]

    return discord.Colour.from_rgb(rgba[0], rgba[1], rgba[2])


def get_coords_formatted(x, y, z):
    return "X: **__%s__** Y: **__%s__** Z: **__%s__**" % (x, y, z)


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
        add_embeds = []

        if data["type"] == "jump":
            try:
                from_x: int = int(data["jump"][0])
                from_y: int = int(data["jump"][1])
                from_z: int = int(data["jump"][2])

                to_x: int = int(data["jump"][3])
                to_y: int = int(data["jump"][4])
                to_z: int = int(data["jump"][5])

                rot_steps: int = int(data["rot"])

                player: str = data["player"]
            except (ValueError, IndexError, KeyError):
                self.response(400)
                return

            embed.set_author(name="%s: JUMP" % data["name"], icon_url="")

            mov_x = to_x - from_x
            mov_y = to_y - from_y
            mov_z = to_z - from_z

            embed.add_field(name="Coordinates", value="**Current**: %s\n**Previous**: %s\n**Movement**: %s" % (get_coords_formatted(to_x, to_y, to_z), get_coords_formatted(from_x, from_y, from_z), get_coords_formatted(mov_x, mov_y, mov_z)))

            if rot_steps != 0:
                embed.add_field(name="Rotation", value="**Steps**: **__%s__**" % rot_steps)

            if player != "":
                embed.add_field(name="Initiated by", value="**__%s__**" % player)

            embed.color = get_color_for_string(data["name"])
        elif data["type"] == "cancel_jump":
            try:
                player: str = data["player"]
                name: str = data["name"]
            except KeyError:
                self.response(400)
                return

            embed.set_author(name="%s: CANCELLED JUMP" % name)

            if player != "":
                embed.add_field(name="Initiated by", value="**__%s__**" % player)

            embed.color = get_color_for_string(data["name"])
        elif data["type"] == "hyper":
            try:
                to: bool = data["to"]
                name: str = data["name"]
                player: str = data["player"]
            except KeyError:
                self.response(400)
                return

            embed.set_author(name="%s: %s HYPERSPACE" % (name, "TO" if to else "FROM"))

            if player != "":
                embed.add_field(name="Initiated by", value="**__%s__**" % player)

            embed.color = get_color_for_string(data["name"])
        elif data["type"] == "pos":
            try:
                pos = data["pos"]
                o = data["o"]
                name = data["name"]

                x = int(pos[0])
                y = int(pos[1])
                z = int(pos[2])

                o_x = int(o[0])
                o_z = int(o[1])

                mass = data["mass"]
                energy_percent = data["energy"]
                dim = data["dim"]
            except (ValueError, IndexError):
                self.response(400)
                return


            embed.set_author(name="Current position of \"%s\"" % name, icon_url="")
            embed.add_field(name="Dimension", value=dim)
            embed.add_field(name="Pos", value=get_coords_formatted(x, y, z))
            embed.add_field(name="Orientation", value="**X**: **__%s__** **Z**: **__%s__**" % (o_x, o_z))
            embed.add_field(name="Mass", value="**__%s__**" % mass)
            embed.add_field(name="Energy", value="**__%s%%__**" % energy_percent)

            embed.color = get_color_for_string(name)
        elif data["type"] == "radarScan":
            try:
                results = data["results"]
                player = data["player"]
                name =  data["name"]
            except KeyError:
                self.response(400)
                return

            embed.set_author(name="%s: RADAR SCAN" % name, icon_url="")

            if player != "":
                embed.add_field(name="Initiated by", value="**__%s__**" % player, inline=False)

            maxsize = 10
            for chunk in [results[i:i + maxsize] for i in range(0, len(results), maxsize)]:
                add_embed = discord.Embed()
                add_embed.color = get_color_for_string(name)
                add_embed.add_field(name="Results (%s left)" % len(chunk), value="\n".join(data["results"]), inline=False)

                add_embeds.append(add_embed)

            embed.color = get_color_for_string(name)
        elif data["type"] == "intruder":
            embed.set_author(name="INTRUDER ALERT")
            embed.colour = 0xFF0000

            try:
                coords = data["coords"]

                embed.add_field(name="Intruder:", value=data["intruder"], inline=False)
                embed.add_field(name="XYZ:", value="%s, %s, %s" % (coords[0], coords[1], coords[2]), inline=False)
                embed.add_field(name="Range:", value=data["range"], inline=False)
            except KeyError:
                self.response(400)
                return 
        else:
            self.response(400)
            return

        webhook.send(embeds=[embed] + add_embeds, username="Interstellar2", avatar_url="https://raw.githubusercontent.com/LemADEC"
                                                                       "/WarpDrive/MC1.12/src/main"
                                                                       "/resources/assets/warpdrive/textures/blocks"
                                                                       "/movement/ship_core"
                                                                       "-right_online.png")

        self.response(200)


server_address = ('', 4248)
httpd = HTTPServer(server_address, ProxyHandler)
print("Starting server...")
httpd.serve_forever()