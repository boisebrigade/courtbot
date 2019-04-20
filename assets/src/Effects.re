let removeTokenFromStorage = () =>
  Dom_storage.(localStorage |> removeItem("jwt"));

let saveTokenToStorage = value =>
  Dom_storage.(localStorage |> setItem("jwt", value));

let getTokenFromStorge = () => Dom_storage.(localStorage |> getItem("jwt"));
