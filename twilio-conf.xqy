xquery version "1.0-ml";

module namespace config = "ml-twilio-sms:config:twilio";

declare variable $logging := fn:false();
declare variable $error-level := 1; (: this could prob be a boolean but i expect to extend it :)

declare variable $username := ""; (: username for twilio account :)
declare variable $password := ""; (: ditto for pass :)
declare variable $format := "xml";

(:
  This is the endpoint for the twilio REST API. 
  The API version is given directly after the domain suffix 
:)
declare variable $endpoint := 
  fn:concat(
    "https://api.twilio.com/2010-04-01/Accounts/",
    $username,
    "/SMS/Messages.",
    $format
  ); 

(: Phone number for account :)
declare variable $twilio-number := "";
