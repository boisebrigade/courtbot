type configuration = {
  twilioSid: string,
  twilioToken: string,
  rollbarToken: string,
  importTime: string,
  notificationTime: string,
  timezone: string,
  courtUrl: string,
};

type action =
  | ChangeTwilioSid(string)
  | ChangeTwilioToken(string)
  | ChangeRollbarToken(string)
  | ChangeImportTime(string)
  | ChangeNotificationTime(string)
  | ChangeCourtUrl(string)
  | ChangeTimezone(string)
  | SaveConfiguration;

module GetConfiguration = [%graphql
  {|
    query ConfigurationQuery {
      configuration @bsRecord {
        twilioSid
        twilioToken
        rollbarToken

        importTime
        notificationTime

        timezone

        courtUrl
      }
    }
  |}
];

module GetConfigurationQuery = ReasonApollo.CreateQuery(GetConfiguration);

module SetConfiguration = [%graphql
  {|
    mutation SetConfiguration($twilioSid: String!, $twilioToken: String!, $rollbarToken: String!, $importTime: String!, $notificationTime: String!, $timezone: String!, $courtUrl: String!) {
      setConfiguration(input: {twilioSid: $twilioSid, twilioToken: $twilioToken, rollbarToken: $rollbarToken, importTime: $importTime, notificationTime: $notificationTime, timezone: $timezone, courtUrl: $courtUrl}) {
        twilioSid
        twilioToken
        rollbarToken
        importTime
        notificationTime
        timezone
        courtUrl
      }
    }
  |}
];

module SetConfigurationMutation =
  ReasonApollo.CreateMutation(SetConfiguration);

module Form = {
  let reducer = (action, state) =>
    switch (action) {
    | ChangeTwilioSid(twilioSid) => ReasonReact.Update({...state, twilioSid})
    | ChangeTwilioToken(twilioToken) =>
      ReasonReact.Update({...state, twilioToken})
    | ChangeRollbarToken(rollbarToken) =>
      ReasonReact.Update({...state, rollbarToken})
    | ChangeImportTime(importTime) =>
      ReasonReact.Update({...state, importTime})
    | ChangeNotificationTime(notificationTime) =>
      ReasonReact.Update({...state, notificationTime})
    | ChangeCourtUrl(courtUrl) => ReasonReact.Update({...state, courtUrl})
    | ChangeTimezone(timezone) => ReasonReact.Update({...state, timezone})
    | SaveConfiguration => ReasonReact.NoUpdate
    };

  let component = ReasonReact.reducerComponent(__MODULE__);

  let make =
      (
        ~twilioSid="",
        ~twilioToken="",
        ~rollbarToken="",
        ~importTime="08:00",
        ~notificationTime="13:00",
        ~timezone="EST",
        ~courtUrl="",
        _children,
      ) => {
    ...component,
    initialState: () => {
      twilioSid,
      twilioToken,
      rollbarToken,
      importTime,
      notificationTime,
      timezone,
      courtUrl,
    },
    reducer,
    render: self =>
      <Main title="Configuration">
        <SetConfigurationMutation>
          ...{
               (mutation, _result) =>
                 /* TODO(ts): Use the result in the value prop for inputs */
                 /* TODO(ts): Error handling for when the GQL mutation fails */
                 /* TODO(ts): HTML5 validation, and make twilio components requried */
                 /* TODO(ts): Add phone number + locale configuration options */
                 /* TODO(ts): Merge with Initial Configuration component */
                 <form
                   onSubmit={
                     e => {
                       ReactEvent.Form.preventDefault(e);
                       let setConf =
                         SetConfiguration.make(
                           ~twilioSid=self.state.twilioSid,
                           ~twilioToken=self.state.twilioToken,
                           ~rollbarToken=self.state.rollbarToken,
                           ~importTime=self.state.importTime,
                           ~notificationTime=self.state.notificationTime,
                           ~timezone=self.state.timezone,
                           ~courtUrl=self.state.courtUrl,
                           (),
                         );

                       mutation(~variables=setConf##variables, ()) |> ignore;
                     }
                   }>
                   <Setting title="Twilio API Credentials" help="/">
                     <label htmlFor="twilio_sid">
                       {ReasonReact.string("SID: ")}
                     </label>
                     <input
                       type_="text"
                       className="db mb2 mt1"
                       name="twilio_sid"
                       id="twilio_sid"
                       value={self.state.twilioSid}
                       onChange={
                         e => ChangeTwilioSid(Dom.getValue(e)) |> self.send
                       }
                       required=true
                     />
                     <label htmlFor="twilio_sid">
                       {ReasonReact.string("Auth Token: ")}
                     </label>
                     <input
                       type_="text"
                       className="db mt1 mb2"
                       name="password"
                       id="password"
                       value={self.state.twilioToken}
                       onChange={
                         e => ChangeTwilioToken(Dom.getValue(e)) |> self.send
                       }
                       required=true
                     />
                   </Setting>
                   <Setting title="Rollbar API Credentials" help="/">
                     <label htmlFor="twilio_sid">
                       {ReasonReact.string("Access Token: ")}
                     </label>
                     <input
                       type_="text"
                       className="db mt1"
                       name="twilio_sid"
                       id="twilio_sid"
                       value={self.state.rollbarToken}
                       onChange={
                         e =>
                           ChangeRollbarToken(Dom.getValue(e)) |> self.send
                       }
                     />
                   </Setting>
                   <Setting title="Rollbar" help="/">
                     <label htmlFor="locale">
                       {ReasonReact.string("Locales: ")}
                     </label>
                     <input
                       type_="tel"
                       className="db mt1"
                       name="locale"
                       id="locale"
                     />
                   </Setting>
                   <Setting title="Scheduled" help="/">
                     <div className="mt3">
                       <label htmlFor="import_time">
                         {ReasonReact.string("Import Time: ")}
                       </label>
                       <input
                         type_="time"
                         className="db mt1"
                         name="import_time"
                         id="import_time"
                         value={self.state.importTime}
                         onChange={
                           e =>
                             ChangeImportTime(Dom.getValue(e)) |> self.send
                         }
                       />
                     </div>
                     <div className="mt3">
                       <label htmlFor="notification_time">
                         {ReasonReact.string("Notification Time: ")}
                       </label>
                       <input
                         type_="time"
                         className="db mt1"
                         name="notification_time"
                         id="notification_time"
                         value={self.state.rollbarToken}
                         onChange={
                           e =>
                             ChangeRollbarToken(Dom.getValue(e)) |> self.send
                         }
                       />
                     </div>
                   </Setting>
                   <Setting title="Branding and Contact" help="/">
                     <label htmlFor="court_url">
                       {ReasonReact.string("Court URL: ")}
                     </label>
                     <input
                       type_="url"
                       className="db mt1"
                       name="court_url"
                       id="court_url"
                       value={self.state.rollbarToken}
                       onChange={
                         e =>
                           ChangeRollbarToken(Dom.getValue(e)) |> self.send
                       }
                     />
                   </Setting>
                   <Setting title="System" help="/">
                     <label htmlFor="timezone">
                       {ReasonReact.string("Timezone: ")}
                     </label>
                     <Timezones />
                   </Setting>
                   <input
                     type_="submit"
                     className="db mt3"
                     name="submit"
                     value="Save"
                     id="submit"
                   />
                 </form>
             }
        </SetConfigurationMutation>
      </Main>,
  };
};

let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self => {
    let conf = GetConfiguration.make();
    <GetConfigurationQuery variables=conf##variables>
      ...{
           ({result}) =>
             switch (result) {
             | Loading => <div> {ReasonReact.string("Loading")} </div>
             | Error(_error) => <div> {ReasonReact.string("Error")} </div>
             | Data(data) =>
               switch (data##configuration) {
               | Some({
                   twilioSid,
                   twilioToken,
                   rollbarToken,
                   importTime,
                   notificationTime,
                   timezone,
                   courtUrl,
                 }) =>
                 <Form
                   twilioSid
                   twilioToken
                   rollbarToken
                   importTime
                   notificationTime
                   timezone
                   courtUrl
                 />
               | None => ReasonReact.null
               }
             }
         }
    </GetConfigurationQuery>;
  },
};
