type state = {
  twilioSid: string,
  twilioToken: string,
  rollbarToken: string,
};

type action =
  | ChangeTwilioSid(string)
  | ChangeTwilioToken(string)
  | ChangeRollbarToken(string)
  | SaveConfiguration;

module SetConfiguration = [%graphql
  {|
    mutation SetConfiguration($twilioSid: String!, $twilioToken: String!, $rollbarToken: String!) {
      setConfiguration(input: {twilioSid: $twilioSid, twilioToken: $twilioToken, rollbarToken: $rollbarToken}) {
        twilioSid
        twilioToken
        rollbarToken
      }
    }
  |}
];

module SetConfigurationMutation = ReasonApollo.CreateMutation(SetConfiguration);

let reducer = (action, state) =>
  switch (action) {
  | ChangeTwilioSid(twilioSid) => ReasonReact.Update({...state, twilioSid})
  | ChangeTwilioToken(twilioToken) => ReasonReact.Update({...state, twilioToken})
  | ChangeRollbarToken(rollbarToken) => ReasonReact.Update({...state, rollbarToken})
  | SaveConfiguration => ReasonReact.NoUpdate
  };

let getValue = event => ReactEvent.Form.target(event)##value;

let component = ReasonReact.reducerComponent(__MODULE__);

let make = (~twilioSid="", ~twilioToken="", ~rollbarToken="", _children) => {
  ...component,
  initialState: () => {twilioSid, twilioToken, rollbarToken},
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
                         (),
                       );

                     mutation(~variables=setConf##variables, ()) |> ignore;
                   }
                 }>
                 <fieldset className="bn">
                   <legend className="f3"> {ReasonReact.string("Twilio")} <Help href="/" /> </legend>
                   <div className="mt3 ml2">
                     <label htmlFor="twilio_sid"> {ReasonReact.string("SID: ")} </label>
                     <input
                       type_="text"
                       className="db mb2 mt1"
                       placeholder="SID"
                       name="twilio_sid"
                       id="twilio_sid"
                       value={self.state.twilioSid}
                       onChange={e => ChangeTwilioSid(getValue(e)) |> self.send}
                     />
                     <label htmlFor="twilio_sid"> {ReasonReact.string("Auth Token: ")} </label>
                     <input
                       type_="text"
                       className="db mt1"
                       placeholder="Token"
                       name="password"
                       id="password"
                       value={self.state.twilioToken}
                       onChange={e => ChangeTwilioToken(getValue(e)) |> self.send}
                     />
                   </div>
                 </fieldset>
                 <fieldset className="mt3 bn">
                   <legend className="f3"> {ReasonReact.string("Rollbar")} <Help href="/" /> </legend>
                   <div className="mt3 ml2">
                     <label htmlFor="twilio_sid"> {ReasonReact.string("Access Token: ")} </label>
                     <input
                       type_="text"
                       className="db mt1"
                       placeholder="Token"
                       name="twilio_sid"
                       id="twilio_sid"
                       value={self.state.rollbarToken}
                       onChange={e => ChangeRollbarToken(getValue(e)) |> self.send}
                     />
                   </div>
                 </fieldset>
                 <input type_="submit" className="db mt3" name="submit" value="Save" id="submit" />
               </form>
           }
      </SetConfigurationMutation>
    </Main>,
};
