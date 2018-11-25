let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self =>
    <div className="flex flex-column bg-near-white w5 h-100">
      <div className="h5 w-70 center flex items-center justify-center">
        <Link href="/"> {ReasonReact.string("CB")} </Link>
      </div>
      <nav className="bt b--black-10 w-70 center">
        <ul className="list pl0 mb3 montserrat">
          <li className="mt3 mb2 pl1">
            <Link href="/"> {ReasonReact.string("Dashboard")} </Link>
          </li>
          <li className="mt3 mb2 pl1">
            <Link href="/configuration">
              {ReasonReact.string("Configuration")}
            </Link>
          </li>
          <li className="mt3 mb2 pl1">
            <Link href="/importer"> {ReasonReact.string("Importer")} </Link>
          </li>
        </ul>
      </nav>
    </div>,
};
