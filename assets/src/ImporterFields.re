module GetImporterFields = [%graphql
  {|
    query ImporterField {
      importField {
        from
        to
        type
        format
        order
      }
    }
  |}
];

module GetImporterFieldsQuery = ReasonApollo.CreateQuery(GetImporterFields);

let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self => {
    let conf = GetImporterFields.make();
    <GetImporterFieldsQuery variables=conf##variables>
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
    </GetImporterFieldsQuery>;
  },
};
