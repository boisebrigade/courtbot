let component = ReasonReact.statelessComponent("Stats");

let make = (_children) => {
  ...component,
  render: _self => {
    <Main title="Stats">
      (ReasonReact.string("testing"))
    </Main>
  },
};
