module GetImporterConfiguration = [%graphql
  {|
    query ImporterConfiguration {
      importerConfiguration {
        origin
        source
        kind
      }
    }
  |}
];

module GetImporterConfigurationQuery = ReasonApollo.CreateQuery(GetImporterConfiguration);

let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self => {
    let conf = GetImporterConfiguration.make();
    <GetImporterConfigurationQuery variables=conf##variables>
      ...{
           ({result}) =>
             switch (result) {
             | Loading => <div> {ReasonReact.string("Loading")} </div>
             | Error(error) =>
               Js.log(error);
               <div> {ReasonReact.string("Error")} </div>;
             | Data(data) =>
               let origin =
                 switch (data##configuration) {
                 | Some(configuration) => configuration##origin
                 | None => ""
                 };

               let source =
                 switch (data##configuration) {
                 | Some(configuration) => configuration##source
                 | None => ""
                 };

               let kind =
                 switch (data##configuration) {
                 | Some(configuration) => configuration##kind
                 | None => ""
                 };

               <Importer origin source kind />;
             }
         }
    </GetImporterConfigurationQuery>;
  },
};
