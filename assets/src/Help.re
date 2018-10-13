let component = ReasonReact.statelessComponent(__MODULE__);

/* ~props={"href": href, "onClick": handleClick(href)} */
let make = (~href, children) => {
  ...component,
  render: _self => <a href> <img className="pl2 h1" src="/question-solid.svg" /> </a>,
};
