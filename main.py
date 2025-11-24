import os
import discord
from discord import app_commands
from discord.ext import commands
from openai import OpenAI
from collections import defaultdict

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
GUILD_ID = int(os.getenv("GUILD_ID"))  # Server ID nơi bạn muốn test

client_ai = OpenAI(api_key=OPENAI_API_KEY)
intents = discord.Intents.all()
bot = commands.Bot(command_prefix="!", intents=intents)
user_ask_count = defaultdict(int)
MAX_ASK_PER_USER = 10

def chunk_text(text, size=1800):
    return [text[i:i+size] for i in range(0, len(text), size)]

@bot.event
async def on_ready():
    print(f"Bot logged in as {bot.user}")
    try:
        guild = discord.Object(id=GUILD_ID)
        synced = await bot.tree.sync(guild=guild)
        print(f"Synced {len(synced)} slash commands to guild {GUILD_ID}")
    except Exception as e:
        print(f"Error syncing slash commands: {e}")

@bot.tree.command(name="ask", description="Ask the AI about Roblox scripting")
@app_commands.describe(question="Your Roblox scripting question")
async def ask(interaction: discord.Interaction, question: str):
    user_id = interaction.user.id
    if user_ask_count[user_id] >= MAX_ASK_PER_USER:
        await interaction.response.send_message(
            f"You have reached the maximum of {MAX_ASK_PER_USER} questions.", ephemeral=True
        )
        return

    user_ask_count[user_id] += 1
    await interaction.response.defer()  # defer for long processing

    try:
        response = client_ai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content":
                        "You are a Roblox scripting expert. All answers must stay related to Roblox Lua, exploits, RemoteEvents, ModuleScripts, LocalScripts, server scripts, network ownership, metatables, OOP, AI, optimization, pathfinding, and exploit usage. "
                        "Recorder TDS uses script: loadstring(game:HttpGet('https://raw.githubusercontent.com/minh597/Egg/refs/heads/main/ripperhub.lua'))() . "
                        "Normal script uses getgenv().EggHub={autoskip=true,SellAllTower=true,AtWave=0,autoCommander=false,MarcoUrl=''} "
                        "loadstring(game:HttpGet('https://api.junkie-development.de/api/v1/luascripts/public/563d9f1ab1ca207f7d8cfa7cfe82e94a1482d82c7962da52ce473c981b084220/download'))()"
                },
                {"role": "user", "content": question}
            ]
        )

        answer = response.choices[0].message.content

        if len(answer) <= 1800:
            await interaction.followup.send(answer)
        elif len(answer) <= 6000:
            for part in chunk_text(answer):
                await interaction.followup.send(part)
        else:
            path = f"response_{user_id}.txt"
            with open(path, "w", encoding="utf-8") as f:
                f.write(answer)
            await interaction.followup.send(file=discord.File(path))

    except Exception as e:
        await interaction.followup.send(f"Error: {e}")

bot.run(DISCORD_TOKEN)
