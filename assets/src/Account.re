let component = ReasonReact.statelessComponent("Account");

let make = (_children) => {
  ...component,
  render: _self => {
    <Main title="Account">
      (ReasonReact.string("testing"))
    </Main>
  },
};
