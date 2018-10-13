let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self => <Main title="Stats"> {ReasonReact.string("Coming Soon!")} </Main>,
};
