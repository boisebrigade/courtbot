let component = ReasonReact.statelessComponent("Aside");

let make = (_children) => {
  ...component,
  render: _self => {
    <div className="flex flex-column justify-center items-center w-100 h-100">
      <div className="bg-near-white pa3">
        <h3> {ReasonReact.string("Login")} </h3>
        <form>
          <input
            type_="text"
            className="db"
            placeholder="Username"
            name="username"
            id="username" />
          <input
            type_="password"
            className="db mv3"
            placeholder="Password"
            name="password"
            id="password" />
          <input
            type_="submit"
            className="db ml-auto"
            name="submit"
            id="submit" />
        </form>
      </div>
    </div>
  },
};
