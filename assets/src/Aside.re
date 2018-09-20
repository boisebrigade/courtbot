let component = ReasonReact.statelessComponent("Aside");

let make = (_children) => {
  ...component,
  render: _self => {
    <div className="flex flex-column bg-near-white w5 h-100">
      <div className="h5 w-70 center flex items-center">
        <img src="/courtbot.png" />
      </div>
      <nav className="bt b--black-10 w-70 center">
        <ul className="list pl0 mb3 montserrat">
          <li className="mt3 mb2 pl1">
          <Link href="/configuration">(ReasonReact.string("Configuration"))</Link>
          </li>
          <li className="mt3 mb2 pl1">
          <Link href="/importer">(ReasonReact.string("Importer"))</Link>
          </li>
          <li className="mt3 mb2 pl1">
          <Link href="/stats">(ReasonReact.string("Stats"))</Link>
          </li>
        </ul>
      </nav>
      <div className="mta h3 flex flex-column justify-center items-center bt b--black-10 w-70 center montserrat">
      <Link href="/account">(ReasonReact.string("Account"))</Link>
      </div>
    </div>
  },
};
