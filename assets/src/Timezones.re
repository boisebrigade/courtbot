let component = ReasonReact.statelessComponent(__MODULE__);

let make = _children => {
  ...component,
  render: _self =>
    <select name="timezone" className="w4">
      <option />
      <option value="Etc/GMT+12"> {ReasonReact.string("(GMT-12:00) International Date Line West")} </option>
      <option value="Pacific/Midway"> {ReasonReact.string("(GMT-11:00) Midway Island, Samoa")} </option>
      <option value="Pacific/Honolulu"> {ReasonReact.string("(GMT-10:00) Hawaii")} </option>
      <option value="US/Alaska"> {ReasonReact.string("(GMT-09:00) Alaska")} </option>
      <option value="America/Los_Angeles"> {ReasonReact.string("(GMT-08:00) Pacific Time (US & Canada)")} </option>
      <option value="America/Tijuana"> {ReasonReact.string("(GMT-08:00) Tijuana, Baja California")} </option>
      <option value="US/Arizona"> {ReasonReact.string("(GMT-07:00) Arizona")} </option>
      <option value="America/Chihuahua"> {ReasonReact.string("(GMT-07:00) Chihuahua, La Paz, Mazatlan")} </option>
      <option value="US/Mountain"> {ReasonReact.string("(GMT-07:00) Mountain Time (US & Canada)")} </option>
      <option value="America/Managua"> {ReasonReact.string("(GMT-06:00) Central America")} </option>
      <option value="US/Central"> {ReasonReact.string("(GMT-06:00) Central Time (US & Canada)")} </option>
      <option value="America/Mexico_City">
        {ReasonReact.string("(GMT-06:00) Guadalajara, Mexico City, Monterrey")}
      </option>
      <option value="Canada/Saskatchewan"> {ReasonReact.string("(GMT-06:00) Saskatchewa")} </option>
      <option value="America/Bogota"> {ReasonReact.string("(GMT-05:00) Bogota, Lima, Quito, Rio Branco")} </option>
      <option value="US/Eastern"> {ReasonReact.string("(GMT-05:00) Eastern Time (US & Canada)")} </option>
      <option value="US/East-Indiana"> {ReasonReact.string("(GMT-05:00) Indiana (East)")} </option>
      <option value="Canada/Atlantic"> {ReasonReact.string("(GMT-04:00) Atlantic Time (Canada)")} </option>
      <option value="America/Caracas"> {ReasonReact.string("(GMT-04:00) Caracas, La Paz")} </option>
      <option value="America/Manaus"> {ReasonReact.string("(GMT-04:00) Manaus")} </option>
      <option value="America/Santiago"> {ReasonReact.string("(GMT-04:00) Santiago")} </option>
      <option value="Canada/Newfoundland"> {ReasonReact.string("(GMT-03:30) Newfoundland")} </option>
      <option value="America/Sao_Paulo"> {ReasonReact.string("(GMT-03:00) Brasilia")} </option>
      <option value="America/Argentina/Buenos_Aires">
        {ReasonReact.string("(GMT-03:00) Buenos Aires, Georgetown")}
      </option>
      <option value="America/Godthab"> {ReasonReact.string("(GMT-03:00) Greenland")} </option>
      <option value="America/Montevideo"> {ReasonReact.string("(GMT-03:00) Montevideo")} </option>
      <option value="America/Noronha"> {ReasonReact.string("(GMT-02:00) Mid-Atlantic")} </option>
      <option value="Atlantic/Cape_Verde"> {ReasonReact.string("(GMT-01:00) Cape Verde Is.")} </option>
      <option value="Atlantic/Azores"> {ReasonReact.string("(GMT-01:00) Azores")} </option>
      <option value="Africa/Casablanca"> {ReasonReact.string("(GMT+00:00) Casablanca, Monrovia, Reykjavik")} </option>
      <option value="Etc/Greenwich">
        {ReasonReact.string("(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London")}
      </option>
      <option value="Europe/Amsterdam">
        {ReasonReact.string("(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienn")}
      </option>
      <option value="Europe/Belgrade">
        {ReasonReact.string("(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague")}
      </option>
      <option value="Europe/Brussels">
        {ReasonReact.string("(GMT+01:00) Brussels, Copenhagen, Madrid, Paris")}
      </option>
      <option value="Europe/Sarajevo"> {ReasonReact.string("(GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb")} </option>
      <option value="Africa/Lagos"> {ReasonReact.string("(GMT+01:00) West Central Africa")} </option>
      <option value="Asia/Amman"> {ReasonReact.string("(GMT+02:00) Amman")} </option>
      <option value="Europe/Athens"> {ReasonReact.string("(GMT+02:00) Athens, Bucharest, Istanbul")} </option>
      <option value="Asia/Beirut"> {ReasonReact.string("(GMT+02:00) Beirut")} </option>
      <option value="Africa/Cairo"> {ReasonReact.string("(GMT+02:00) Cairo")} </option>
      <option value="Africa/Harare"> {ReasonReact.string("(GMT+02:00) Harare, Pretoria")} </option>
      <option value="Europe/Helsinki">
        {ReasonReact.string("(GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius")}
      </option>
      <option value="Asia/Jerusalem"> {ReasonReact.string("(GMT+02:00) Jerusalem")} </option>
      <option value="Europe/Minsk"> {ReasonReact.string("(GMT+02:00) Minsk")} </option>
      <option value="Africa/Windhoek"> {ReasonReact.string("(GMT+02:00) Windhoek")} </option>
      <option value="Asia/Kuwait"> {ReasonReact.string("(GMT+03:00) Kuwait, Riyadh, Baghdad")} </option>
      <option value="Europe/Moscow"> {ReasonReact.string("(GMT+03:00) Moscow, St. Petersburg, Volgograd")} </option>
      <option value="Africa/Nairobi"> {ReasonReact.string("(GMT+03:00) Nairobi")} </option>
      <option value="Asia/Tbilisi"> {ReasonReact.string("(GMT+03:00) Tbilisi")} </option>
      <option value="Asia/Tehran"> {ReasonReact.string("(GMT+03:30) Tehran")} </option>
      <option value="Asia/Muscat"> {ReasonReact.string("(GMT+04:00) Abu Dhabi, Muscat")} </option>
      <option value="Asia/Baku"> {ReasonReact.string("(GMT+04:00) Baku")} </option>
      <option value="Asia/Yerevan"> {ReasonReact.string("(GMT+04:00) Yerevan")} </option>
      <option value="Asia/Kabul"> {ReasonReact.string("(GMT+04:30) Kabul")} </option>
      <option value="Asia/Yekaterinburg"> {ReasonReact.string("(GMT+05:00) Yekaterinburg")} </option>
      <option value="Asia/Karachi"> {ReasonReact.string("(GMT+05:00) Islamabad, Karachi, Tashkent")} </option>
      <option value="Asia/Calcutta"> {ReasonReact.string("(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi")} </option>
      <option value="Asia/Calcutta"> {ReasonReact.string("(GMT+05:30) Sri Jayawardenapura")} </option>
      <option value="Asia/Katmandu"> {ReasonReact.string("(GMT+05:45) Kathmandu")} </option>
      <option value="Asia/Almaty"> {ReasonReact.string("(GMT+06:00) Almaty, Novosibirsk")} </option>
      <option value="Asia/Dhaka"> {ReasonReact.string("(GMT+06:00) Astana, Dhaka")} </option>
      <option value="Asia/Rangoon"> {ReasonReact.string("(GMT+06:30) Yangon (Rangoon)")} </option>
      <option value="Asia/Bangkok"> {ReasonReact.string("(GMT+07:00) Bangkok, Hanoi, Jakarta")} </option>
      <option value="Asia/Krasnoyarsk"> {ReasonReact.string("(GMT+07:00) Krasnoyarsk")} </option>
      <option value="Asia/Hong_Kong">
        {ReasonReact.string("(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi")}
      </option>
      <option value="Asia/Kuala_Lumpur"> {ReasonReact.string("(GMT+08:00) Kuala Lumpur, Singapore")} </option>
      <option value="Asia/Irkutsk"> {ReasonReact.string("(GMT+08:00) Irkutsk, Ulaan Bataar")} </option>
      <option value="Australia/Perth"> {ReasonReact.string("(GMT+08:00) Perth")} </option>
      <option value="Asia/Taipei"> {ReasonReact.string("(GMT+08:00) Taipei")} </option>
      <option value="Asia/Tokyo"> {ReasonReact.string("(GMT+09:00) Osaka, Sapporo, Tokyo")} </option>
      <option value="Asia/Seoul"> {ReasonReact.string("(GMT+09:00) Seoul")} </option>
      <option value="Asia/Yakutsk"> {ReasonReact.string("(GMT+09:00) Yakutsk")} </option>
      <option value="Australia/Adelaide"> {ReasonReact.string("(GMT+09:30) Adelaide")} </option>
      <option value="Australia/Darwin"> {ReasonReact.string("(GMT+09:30) Darwin")} </option>
      <option value="Australia/Brisbane"> {ReasonReact.string("(GMT+10:00) Brisbane")} </option>
      <option value="Australia/Canberra"> {ReasonReact.string("(GMT+10:00) Canberra, Melbourne, Sydney")} </option>
      <option value="Australia/Hobart"> {ReasonReact.string("(GMT+10:00) Hobart")} </option>
      <option value="Pacific/Guam"> {ReasonReact.string("(GMT+10:00) Guam, Port Moresby")} </option>
      <option value="Asia/Vladivostok"> {ReasonReact.string("(GMT+10:00) Vladivostok")} </option>
      <option value="Asia/Magadan"> {ReasonReact.string("(GMT+11:00) Magadan, Solomon Is., New Caledonia")} </option>
      <option value="Pacific/Auckland"> {ReasonReact.string("(GMT+12:00) Auckland, Wellington")} </option>
      <option value="Pacific/Fiji"> {ReasonReact.string("(GMT+12:00) Fiji, Kamchatka, Marshall Is.")} </option>
      <option value="Pacific/Tongatapu"> {ReasonReact.string("(GMT+13:00) Nuku'alofa")} </option>
    </select>,
};
