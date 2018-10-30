let component = ReasonReact.statelessComponent(__MODULE__);

/* ~props={"href": href, "onClick": handleClick(href)} */
let make = (~href, _children) => {
  ...component,
  render: _self => <a href> <i className="fas fa-question f7 pl2 black" /> </a>,
};
