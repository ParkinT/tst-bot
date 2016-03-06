TIC-SLACK-TOE
=============================

## Play a game in Slack

If you use Slack for your team communication, there are days when it seems the chatter is endless.  It is great to have a 'diversion' (beyond the weird posts your teammates make in #random).  This **is** that diversion.

Tic-Slack-Toe, however, is not your grandfather's Xs and Os game.  This is the 21st century and we are up for more of a challenge.  In this game the board is **four** by **four**!!

### How to play

For your first game, just Type `tic-slack-toe` in the channel where the integration has been setup.

The grid is divided and you can reference each position by its
**COL**umn and **ROW**.  Beginning in the upper-left corner, the first position is **col** 1 in **row** 1.  Each command is a position where you wish to place your mark.  After **you** have placed a mark the bot will make a play and redisplay the board for you.

You can return to a game in progress at any time; the state of the board will be remembered.  And your game is independent of any others.
When you return, to recall the current board just type `tic`.

If you play in different channels, each game will be independent.

You can always be reminded of these commands by typing `tic help`.

---

Your game will **only be visible to you**.  So your boss will not know you are spending time playing Tic-Slack-Toe while listening on that boring conference call.


### Set up

You add this bot to your Slack channel(s) in the 'Custom Integration' section of the 'Outgoing Webhooks' configuration.

![Choose 'Configure'](configure.png?raw=true)

![Click 'Add Configuration'](add_configuration.png?raw=true)

![Click 'Add Outgoing Webhooks](add_outgoing_webhooks_integration.png?raw=true)

![Add a Custom Integration](custom_integrations.png?raw=true)

![Fill in details](custom_integration_1.png?raw=true)
![Fill in details](custom_integration_2.png?raw=true)

---

This was fun to create but is certainly not complete.  It is also not perfect.  Please, please, please Fork/Hack/Commit.  Pull Requests are welcomed and encouraged.

Ideas that you will see I made allowances in the code to accommodate
include:

  - Customizable Emoji (player and bot)
  - Option to make your [final?] game visible in the channel
  - Statistics of Wins and Losses against the bot

