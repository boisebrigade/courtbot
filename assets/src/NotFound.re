let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self =>
    <Main title="Not Found">
      {
        ReasonReact.string(
          "Sorry, we couldn't find what you were looking for.",
        )
      }
    </Main>,
};
