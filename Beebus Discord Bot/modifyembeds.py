import nextcord
from nextcord.ext import commands
from nextcord import Interaction
from datetime import datetime as DateTime
import mysql.connector
from mysql.connector import Error

class modifyembeds(commands.Cog):
    def __init__(self, client):
        self.client = client
    
    @nextcord.slash_command(name = "newserver", description = "just a command!", guild_ids = [813168934739902515])
    async def newserver(self, interaction: Interaction, jobid: str, players: str):
        try:
            connection = mysql.connector.connect(host = "localhost", database = "serverlist", user = "root", password = "root")

            createquery = """CREATE TABLE """ + jobid + """ (
                Id int(11) NOT NULL AUTO_INCREMENT,
                MessageId char(27) NOT NULL,
                Players longtext NOT NULL,
                PRIMARY KEY (Id)) """

            cursor = connection.cursor()
            cursor.execute(createquery)

        except Error as error:
            print("Failed to store data table!: {}".format(error))

        finally:
            if connection.is_connected():
                insertquery = "INSERT INTO " + jobid + " (MessageId, Players) VALUES (%S, %S)"
                insertvalues = (str(interaction.user), players)

                cursor.execute(insertquery, insertvalues)
                connection.commit()

                await interaction.response.send_message("Stored")

                cursor.close()
                connection.close()

def setup(client):
    client.add_cog(modifyembeds(client))
    