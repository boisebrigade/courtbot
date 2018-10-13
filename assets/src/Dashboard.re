module GetDashboard = [%graphql
  {|
      query DashboardQuery {
        configuration {
          twilioSid,
          twilioToken,
          rollbarToken
        }
      }
    |}
];

module GetDashboardQuery = ReasonApollo.CreateQuery(GetDashboard);

let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self => {
    let conf = GetDashboard.make();
    <GetDashboardQuery variables=conf##variables>
      ...{({result}) => <Main title="Dashboard"> {ReasonReact.string("Coming Soon!")} </Main>}
    </GetDashboardQuery>;
  },
};
