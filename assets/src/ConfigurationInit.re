module GetConfiguration = [%graphql
  {|
    query ConfigurationQuery {
      configuration {
        twilioSid,
        twilioToken,
        rollbarToken
      }
    }
  |}
];

module GetConfigurationQuery = ReasonApollo.CreateQuery(GetConfiguration);

let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self => {
    let conf = GetConfiguration.make();
    <GetConfigurationQuery variables=conf##variables>
      ...{
           ({result}) =>
             switch (result) {
             | Loading => <div> {ReasonReact.string("Loading")} </div>
             | Error(error) =>
               Js.log(error);
               <div> {ReasonReact.string("Error")} </div>;
             | Data(data) =>
               let twilioSid =
                 switch (data##configuration) {
                 | Some(configuration) => configuration##twilioSid
                 | None => ""
                 };

               let twilioToken =
                 switch (data##configuration) {
                 | Some(configuration) => configuration##twilioToken
                 | None => ""
                 };

               let rollbarToken =
                 switch (data##configuration) {
                 | Some(configuration) => configuration##rollbarToken
                 | None => ""
                 };

               <Configuration twilioSid twilioToken rollbarToken />;
             }
         }
    </GetConfigurationQuery>;
  },
};
