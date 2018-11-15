let component = ReasonReact.statelessComponent(__MODULE__);

let make = (~title, ~help, children) => {
  ...component,
  render: _self =>
    <fieldset className="bn mt4">
      <legend className="f4 pb2 bb"> {ReasonReact.string(title)} <Help href=help /> </legend>
      <div className="mt3"> {ReasonReact.array(children)} </div>
    </fieldset>,
};
