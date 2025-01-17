open Discord
open Promise
open Shared
open Exceptions

let {brightIdVerificationEndpoint, brightIdAppDeeplink, brightIdLinkVerificationEndpoint} = module(
  Endpoints
)
let {context} = module(Constants)

Env.createEnv()

let config = switch Env.getConfig() {
| Ok(config) => config
| Error(err) => err->Env.EnvError->raise
}

let getRolebyRoleId = (guildRoleManager, roleId) => {
  let guildRole =
    guildRoleManager->RoleManager.getCache->Collection.get(roleId)->Js.Nullable.toOption

  switch guildRole {
  | Some(guildRole) => guildRole
  | None => ButtonVerifyHandlerError("Could not find a role with the id " ++ roleId)->raise
  }
}

let getGuildDataFromGist = (guilds, guildId, interaction) => {
  let guildData = guilds->Js.Dict.get(guildId)
  switch guildData {
  | None =>
    interaction
    ->Interaction.editReply(
      ~options={"content": "Failed to retreive data for this Discord Guild"},
      (),
    )
    ->ignore
    ButtonVerifyHandlerError("Failed to retreive data for this Discord Guild")->raise
  | Some(guildData) => guildData
  }
}

let addRoleToMember = (guildRole, member) => {
  let guildMemberRoleManager = member->GuildMember.getGuildMemberRoleManager
  guildMemberRoleManager->GuildMemberRoleManager.add(guildRole, ())
}

let noMultipleContextIds = (member, interaction) => {
  let options = {
    "content": "Hey, I recognize you, but you have two or more Discord accounts linked to the same BrightID. Unfortunately, the bot doesn't support this yet and can't assign you the BrightID role",
    "ephemeral": true,
  }
  interaction
  ->Interaction.followUp(~options, ())
  ->then(_ =>
    ButtonVerifyHandlerError(
      `${member->GuildMember.getDisplayName}: Verification Info can not be retrieved from more than one Discord account.`,
    )->reject
  )
}

let handleUnverifiedGuildMember = (errorNum, interaction) => {
  switch errorNum {
  | 2 =>
    let options = {
      "content": "Please scan the above QR code in the BrightID mobile app",
      "ephemeral": true,
    }
    interaction->Interaction.followUp(~options, ())->then(_ => resolve())

  | 3 =>
    let options = {
      "content": "Please scan the above QR code in the BrightID mobile app",
      "ephemeral": true,
    }
    interaction->Interaction.followUp(~options, ())->then(_ => resolve())
  | 4 =>
    let options = {
      "content": "Whoops! You haven't received a sponsor. There are plenty of apps with free sponsors, such as the [EIDI Faucet](https://idchain.one/begin/). \n\n See all the apps available at https://apps.brightid.org",
      "ephemeral": true,
    }
    interaction->Interaction.followUp(~options, ())->then(_ => resolve())
  | _ =>
    let options = {
      "content": "Something unexpected happened. Please try again later.",
      "ephemeral": true,
    }
    interaction->Interaction.followUp(~options, ())->then(_ => resolve())
  }
}

let execute = interaction => {
  open Utils

  let guild = interaction->Interaction.getGuild
  let member = interaction->Interaction.getGuildMember
  let guildRoleManager = guild->Guild.getGuildRoleManager

  let guildId = guild->Guild.getGuildId

  interaction
  ->Interaction.deferReply(~options={"ephemeral": true}, ())
  ->then(_ => {
    let config = Gist.makeGistConfig(
      ~id=config["gistId"],
      ~name="guildData.json",
      ~token=config["githubAccessToken"],
    )
    Gist.ReadGist.content(~config, ~decoder=Decode.Decode_Gist.brightIdGuilds)->then(guilds => {
      let guildData = guilds->getGuildDataFromGist(guildId, interaction)
      switch guildData.roleId {
      | None =>
        let options = {
          "content": "Hi, sorry about that. I couldn't retrieve the data for this server from BrightID. Try reinviting the bot. \n\n **Note: This will create a new role BrightID Role.**",
        }
        interaction
        ->Interaction.editReply(~options, ())
        ->then(_ => ButtonVerifyHandlerError(`Guild does not have a saved roleId`)->reject)
      | Some(roleId) =>
        member
        ->Services_VerificationInfo.getBrightIdVerification
        ->then(
          verificationInfo => {
            switch verificationInfo {
            | VerificationInfo({contextIds, unique}) =>
              let contextIdsLength = contextIds->Array.length
              switch (contextIdsLength, unique) {
              | (_, true) =>
                let guildRole = roleId->getRolebyRoleId(guildRoleManager, _)
                guildRole
                ->addRoleToMember(member)
                ->then(
                  _ => {
                    let options = {
                      "content": `Hey, I recognize you! I just gave you the \`${guildRole->Role.getName}\` role. You are now BrightID verified in ${guild->Guild.getGuildName} server!`,
                      "ephemeral": true,
                    }
                    interaction->Interaction.followUp(~options, ())
                  },
                )
                ->then(_ => resolve())
              | (0, _) =>
                let options = {
                  "content": `The BrightID has not been linked to Discord. That means the qr code has not been properly scanned!`,
                  "ephemeral": true,
                }
                interaction->Interaction.followUp(~options, ())->then(_ => resolve())
              | (_, false) =>
                let options = {
                  "content": "Hey, I recognize you, but your account seems to be linked to a possible sybil attack. You are not properly BrightID verified. If this is a mistake, contact one of the support channels",
                  "ephemeral": true,
                }
                interaction
                ->Interaction.followUp(~options, ())
                ->then(
                  _ =>
                    ButtonVerifyHandlerError(
                      `${member->GuildMember.getDisplayName} is not unique`,
                    )->reject,
                )
              }
            }
          },
        )
        ->catch(
          async e => {
            switch e {
            | JsError(obj) =>
              let options = {
                "content": "Something unexpected happened. Try again later",
                "ephemeral": true,
              }
              let _ = await Interaction.followUp(interaction, ~options, ())
              JsError(obj)->raise
            | Exceptions.BrightIdError({errorNum}) =>
              let _ = await errorNum->handleUnverifiedGuildMember(interaction)
            | _ => e->raise
            }
          },
        )
      }
    })
  })
}

let customId = "verify"
