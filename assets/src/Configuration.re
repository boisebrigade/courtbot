let component = ReasonReact.statelessComponent("Configuration");

let make = (_children) => {
  ...component,
  render: _self => {
    <Main title="Configuration">
      <form>
        <fieldset className="bn ml4">
          <legend className="f3">{ReasonReact.string("Twilio")}</legend>
          <label htmlFor="twilio_sid">{ReasonReact.string("SID")}</label>
          <input
            type_="text"
            className="db mb2"
            placeholder="SID"
            name="twilio_sid"
            id="twilio_sid" />

          <label htmlFor="twilio_sid">{ReasonReact.string("Auth Token")}</label>
          <input
            type_="text"
            className="db"
            placeholder="Token"
            name="password"
            id="password" />
        </fieldset>

        <fieldset className="mt3 bn">
          <legend className="f3" >{ReasonReact.string("Rollbar")}</legend>
          <label htmlFor="twilio_sid">{ReasonReact.string("Access Token")}</label>
          <input
            type_="text"
            className="db"
            placeholder="Token"
            name="twilio_sid"
            id="twilio_sid" />
        </fieldset>

        <input
            type_="submit"
            className="db mt3"
            name="submit"
            value="Save"
            id="submit" />
      </form>
    </Main>
  },
};
