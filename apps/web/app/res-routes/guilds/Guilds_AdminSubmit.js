// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Remix from "remix";
import * as Js_dict from "../../../../../node_modules/rescript/lib/es6/js_dict.js";
import * as $$Promise from "../../../../../node_modules/@ryyppy/rescript-promise/src/Promise.js";
import * as AuthServer from "../../AuthServer.js";
import * as Belt_Array from "../../../../../node_modules/rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "../../../../../node_modules/rescript/lib/es6/belt_Option.js";
import * as Decode$Shared from "../../../node_modules/@brightidbot/shared/src/Decode.js";
import * as WebUtils_Gist from "../../utils/WebUtils_Gist.js";
import * as Caml_exceptions from "../../../../../node_modules/rescript/lib/es6/caml_exceptions.js";
import * as Webapi__FormData from "../../../../../node_modules/rescript-webapi/src/Webapi/Webapi__FormData.js";
import * as Caml_js_exceptions from "../../../../../node_modules/rescript/lib/es6/caml_js_exceptions.js";

var EmptySubmit = /* @__PURE__ */Caml_exceptions.create("Guilds_AdminSubmit.EmptySubmit");

var GuildDoesNotExist = /* @__PURE__ */Caml_exceptions.create("Guilds_AdminSubmit.GuildDoesNotExist");

var botToken = process.env.DISCORD_API_TOKEN;

function loader(param) {
  var guildId = Belt_Option.getExn(Js_dict.get(param.params, "guildId"));
  return Promise.resolve(Remix.redirect("/guilds/" + guildId + "/admin"));
}

function modifyRoleUrl(guildId, roleId) {
  return "https://discord.com/api/guilds/" + guildId + "/roles/" + roleId + "";
}

function someIfString(entryValue) {
  var match = Webapi__FormData.EntryValue.classify(entryValue);
  if (match.NAME === "File") {
    return ;
  }
  var x = match.VAL;
  if (x === "") {
    return ;
  } else {
    return x;
  }
}

function getIfString(formData, field) {
  return Belt_Option.flatMap(formData.get(field), someIfString);
}

function make(formData) {
  return {
          role: getIfString(formData, "role"),
          inviteLink: getIfString(formData, "inviteLink"),
          sponsorshipAddress: getIfString(formData, "sponsorshipAddress")
        };
}

var Form = {
  someIfString: someIfString,
  getIfString: getIfString,
  make: make
};

async function action(param) {
  var request = param.request;
  var guildId = Belt_Option.getWithDefault(Js_dict.get(param.params, "guildId"), "");
  var exit = 0;
  var data;
  try {
    data = await AuthServer.authenticator.isAuthenticated(request);
    exit = 1;
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn.RE_EXN_ID !== $$Promise.JsError) {
      throw exn;
    }
    
  }
  exit === 1;
  var data$1 = await request.formData();
  var match = make(data$1);
  var sponsorshipAddress = match.sponsorshipAddress;
  var inviteLink = match.inviteLink;
  var role = match.role;
  var config = WebUtils_Gist.makeGistConfig(process.env.GIST_ID, "guildData.json", process.env.GITHUB_ACCESS_TOKEN);
  var content = await WebUtils_Gist.ReadGist.content(config, Decode$Shared.Decode_Gist.brightIdGuilds);
  var entry = Js_dict.get(content, guildId);
  var prevEntry;
  if (entry !== undefined) {
    prevEntry = entry;
  } else {
    throw {
          RE_EXN_ID: GuildDoesNotExist,
          _1: guildId,
          Error: new Error()
        };
  }
  var atleastOneSome = Belt_Array.some([
        role,
        inviteLink,
        sponsorshipAddress
      ], Belt_Option.isSome);
  if (!atleastOneSome) {
    return {
            TAG: /* Error */1,
            _0: {
              RE_EXN_ID: EmptySubmit
            }
          };
  }
  var entry_role = Belt_Option.isSome(role) ? role : prevEntry.role;
  var entry_name = prevEntry.name;
  var entry_inviteLink = Belt_Option.isSome(inviteLink) ? inviteLink : prevEntry.inviteLink;
  var entry_roleId = prevEntry.roleId;
  var entry_sponsorshipAddress = Belt_Option.isSome(sponsorshipAddress) ? sponsorshipAddress : prevEntry.sponsorshipAddress;
  var entry_sponsorshipAddressEth = prevEntry.sponsorshipAddressEth;
  var entry_usedSponsorships = prevEntry.usedSponsorships;
  var entry_assignedSponsorships = prevEntry.assignedSponsorships;
  var entry_premiumSponsorshipsUsed = prevEntry.premiumSponsorshipsUsed;
  var entry_premiumExpirationTimestamp = prevEntry.premiumExpirationTimestamp;
  var entry$1 = {
    role: entry_role,
    name: entry_name,
    inviteLink: entry_inviteLink,
    roleId: entry_roleId,
    sponsorshipAddress: entry_sponsorshipAddress,
    sponsorshipAddressEth: entry_sponsorshipAddressEth,
    usedSponsorships: entry_usedSponsorships,
    assignedSponsorships: entry_assignedSponsorships,
    premiumSponsorshipsUsed: entry_premiumSponsorshipsUsed,
    premiumExpirationTimestamp: entry_premiumExpirationTimestamp
  };
  var data$2;
  try {
    data$2 = await WebUtils_Gist.UpdateGist.updateEntry(content, guildId, entry$1, config);
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    if (e.RE_EXN_ID === $$Promise.JsError) {
      return {
              TAG: /* Error */1,
              _0: {
                RE_EXN_ID: $$Promise.JsError,
                _1: e._1
              }
            };
    }
    throw e;
  }
  return {
          TAG: /* Ok */0,
          _0: data$2
        };
}

export {
  EmptySubmit ,
  GuildDoesNotExist ,
  botToken ,
  loader ,
  modifyRoleUrl ,
  Form ,
  action ,
}
/* botToken Not a pure module */
