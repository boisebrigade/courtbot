let component = ReasonReact.statelessComponent(__MODULE__);

let handleClick = (href, event) =>
  /* the default action will reload the page, which will cause us to lose state */
  if (!ReactEvent.Mouse.defaultPrevented(event)) {
    ReactEvent.Mouse.preventDefault(event);
    ReasonReact.Router.push(href);
  };
/* ~props={"href": href, "onClick": handleClick(href)} */
let make = (~href, children) => {
  ...component,
  render: _self => <span className="pointer underline-hover" href onClick={handleClick(href)}> ...children </span>,
};
