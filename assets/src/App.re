type route =
  | Configuration
  | Importer
  | Stats
  | Account
  | NotFound

type state = {
  route: route,
  needsLogin: bool
};

type action =
  | ChangeRoute(route);

let mapPathToRoute = (url: ReasonReact.Router.url) =>
  switch url.path {
  | [] => Configuration
  | ["configuration"] => Configuration
  | ["importer"] => Importer
  | ["account"] => Account
  | ["stats"] => Stats
  | _ => NotFound
  };

let component = ReasonReact.reducerComponent("App");

let make = _children => {
  ...component,
  initialState: () => {route: Configuration, needsLogin: false},
  didMount: self => {
    let watcherId = ReasonReact.Router.watchUrl(
      (url) => self.send(ChangeRoute(url |> mapPathToRoute))
    )

    self.onUnmount(() => ReasonReact.Router.unwatchUrl(watcherId))
  },
  reducer: (action, _state) =>
    switch (action) {
    | ChangeRoute(route) => ReasonReact.Update({route: route, needsLogin: false})
    },
  render: self => {
    <>
      (
        self.state.needsLogin ?
          <Login /> :
          <>
            <Aside />
            (switch self.state.route {
            | Configuration => <Configuration />
            | Importer => <Importer />
            | Account => <Account />
            | Stats => <Stats />
            | _ => <NotFound />
            })
          </>
        )
    </>
  }
}
