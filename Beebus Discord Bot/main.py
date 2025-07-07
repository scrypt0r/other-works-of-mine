import nextcord

intents = nextcord.Intents.default()
intents.message_content = True

from nextcord.ext import commands
from datetime import datetime as DateTime
from datetime import timezone as TimeZone
#import mysql.connector
#from mysql.connector import Error
import time
import threading
import math

client = commands.Bot(command_prefix = "b!", intents = intents)
servers = {}

@client.event
async def on_ready():
    await client.change_presence(status = nextcord.Status.do_not_disturb, activity = nextcord.Activity(type = nextcord.ActivityType.playing, name = "Hex Conquest"))
    
@client.command(name = "newserver")
async def newserver(context):
    data = context.message.content.split(":")
    index = str(data[1].split(" | ")[1])

    embedMSG = nextcord.Embed(type = "rich", title = "New server created!", color = 0x7f7fff, timestamp = DateTime.now())
    embedMSG.add_field(name = "Location:", value = "Not located yet!", inline = True)
    embedMSG.add_field(name = "PlaceId | JobId:", value = data[1], inline = True)
    embedMSG.add_field(name = "Players by Id | Name:", value = data[2], inline = False)
    embedMSG.set_footer(text = data[3])

    sent = await context.send(embed = embedMSG)

    servers[index] = {
        "MessageId": sent.id,
        "Location": "Not located yet!",
        "ServerData": data[1],
        "Playerlist": data[2],
        "PlayerHistory": {data[2]: (time.time(), 0)},
        "Start": time.time(),
        "StartIso": DateTime.now().replace(tzinfo = TimeZone.utc).isoformat()
    }


    # just me trying out SQL, I guess
    #try:
    #    connection = mysql.connector.connect(host = "localhost", database = "serverlist", user = "root", password = "root")
    #
    #    createquery = """CREATE TABLE """ + data[1] + """ (
    #        JobId varchar(30) NOT NULL,
    #        MessageId bigint(255) NOT NULL,
    #        Players text(65535) NOT NULL,
    #        PRIMARY KEY (JobId)) """
    #
    #    cursor = connection.cursor()
    #    cursor.execute(createquery)

    #except Error as error:
    #    print("Failed to store data table!: {}".format(error))

    #finally:
    #    if connection.is_connected():
    #        insertquery = "INSERT INTO " + data[1] + " (JobId, MessageId, Players) VALUES (%s, %s, %s)"
    #        insertvalues = ("jobid", int(sent.id), "182133293 (Jeralua),")
    #
    #        cursor.execute(insertquery, insertvalues)
    #        connection.commit()
    #
    #        cursor.close()
    #        connection.close()

    def thread():
        while index in servers:
            for playerIndex, timeInfo in servers[index]["PlayerHistory"].items():
                if not timeInfo[0] == -1:
                    servers[index]["PlayerHistory"][playerIndex] = (time.time(), timeInfo[1] + time.time() - timeInfo[0])
        
            time.sleep(1)

    threading.Thread(target = thread).start()

def formatsecstostring(elapsed):
    elapsed = {
        "days": math.floor(elapsed / 3600 / 24),
        "hours": math.floor(elapsed / 3600),
        "minutes": math.floor(elapsed / 60 % 60),
        "seconds": math.floor(elapsed % 60)
    }

    for unit, amount in elapsed.items():
        if amount > 0:
            elapsed[unit] = str(amount) + " " + unit

            if unit == "minutes":
                elapsed[unit] = elapsed[unit] + " and "

            if unit != "seconds" and unit != "minutes":
                elapsed[unit] = elapsed[unit] + ", "
        else:
            elapsed[unit] = ""

    return elapsed["days"] + elapsed["hours"] + elapsed["minutes"] + elapsed["seconds"]

@client.command(name = "setlocation")
async def setlocation(context):
    data = context.message.content.split(":")
    index = data[1].split(" | ")[1]

    if index in servers:
        message = await context.fetch_message(servers[index]["MessageId"])

        if message:
            embedMSG = message.embeds[0]

            embedMSG.set_field_at(0, name = "Location:", value = data[2], inline = True)

            await message.edit(embed = embedMSG)

@client.command(name = "updateplayers")
async def updateplayers(context):
    data = context.message.content.split(":")
    index = data[1].split(" | ")[1]

    if index in servers:
        message = await context.fetch_message(servers[index]["MessageId"])

        if message:
            embedMSG = message.embeds[0]

            embedvalue = embedMSG.fields[2].value
            newembedvalue = ""

            for playerindex in embedvalue.split("\n"):
                add = True

                for playerindex2 in data[3].split(","):
                    if playerindex == playerindex2:
                        add = False

                        if playerindex2 in servers[index]["PlayerHistory"]:
                            servers[index]["PlayerHistory"][playerindex2] = (-1, servers[index]["PlayerHistory"][playerindex2][1])

                        break

                if add == True:
                    newembedvalue = newembedvalue + playerindex + "\n"

            if data[2] != "":
                for playerindex in data[2].split(","):
                    add = True

                    for playerindex2 in embedvalue.split("\n"):
                        if playerindex == playerindex2:
                            add = False
                            break

                    if add == True:
                        newembedvalue = newembedvalue + playerindex + "\n"

                        if not playerindex in servers[index]["PlayerHistory"]:
                            servers[index]["PlayerHistory"][playerindex] = (time.time(), 0)
                        else:
                            servers[index]["PlayerHistory"][playerindex] = (time.time(), servers[index]["PlayerHistory"][playerindex][1])

            if newembedvalue.endswith("\n"):
                newembedvalue = newembedvalue[:-1]

            embedMSG.set_field_at(2, name = "Players by Id | Name:", value = newembedvalue, inline = False)

            await message.edit(embed = embedMSG)

@client.command(name = "closeserver")
async def closeserver(context):
    index = context.message.content.split(":")[1].split(" | ")[1]

    if index in servers:
        message = await context.fetch_message(servers[index]["MessageId"])
 
        if message:
            embedMSG = message.embeds[0]

            embedMSG.title = "Server closed!"
            embedMSG.set_field_at(2, name = "Lifetime:", value = formatsecstostring(time.time() - servers[index]["Start"]), inline = False)

            filename = str(servers[index]["StartIso"][:-7].replace("T", " at ") + " " + index + ".txt").replace(":", ".")

            with open(filename, "w") as file:
                file.write("Server started at: " + servers[index]["StartIso"][:-6] + "\n\n(Times are approximated and are not exact.)\n")

                for playerIndex, datadct in servers[index]["PlayerHistory"].items():
                    file.write(playerIndex + " | " + formatsecstostring(datadct[1]) + "\n")

                file.write("\nServer closed at: " + DateTime.now().replace(tzinfo = TimeZone.utc).isoformat()[:-6])
            
            with open(filename, "rb") as file:
                await message.edit(embed = embedMSG, file = nextcord.File(file, filename))

        del servers[index]
    else:
        print("could not find index")

@client.event
async def on_message(message):
    context = await client.get_context(message)

    if context.valid:
        await client.invoke(context)

    if message.channel.id == 1066555914540294144 and message.author.id != client.user.id:
        await message.delete()

#cogs = []

#for filename in os.listdir("./cogs"):
#    if filename.endswith(".py"):
#        cogs.append("cogs." + filename[:-3])

#if __name__ == "__main__":
#    for cog in cogs:
#        client.load_extension(cog)

# not making a token public lol
client.run()
