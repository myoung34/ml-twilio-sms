(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)
(:
:  Module: Twilio
:
:  Module Namespace:
:      ml-twilio-sms:lib:twilio
:
:  Description:
:      A wrapper that hits the Twilio Restful interface and tries to cleanly
:      determine successes/failures and respond accordingly.
:)
(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

xquery version "1.0-ml";

module namespace tw = "ml-twilio-sms:lib:twilio";
declare namespace http = "xdmp:http";

import module 
  namespace tw-config = "ml-twilio-sms:config:twilio"
  at "/twilio-conf.xqy";

declare variable $username := $tw-config:username;
declare variable $password := $tw-config:password;
declare variable $api-endpoint := $tw-config:endpoint;
declare variable $twilio-number := $tw-config:twilio-number;
declare variable $logging := $tw-config:logging;
declare variable $error-level := $tw-config:error-level;

(: 
  This is the main function. It will attempt to send a text to
  a number with a given body. It handles the success and failures
  returned by the Twilio RESTful interface
:)
declare function tw:send-sms(
  $to as xs:string,
  $body as xs:string
) {
  let $payload :=
    tw:clean(
      fn:concat(
        'From=',
          $twilio-number,
        '&amp;To=',
          $to,
        '&amp;Body=',
          $body
      )
    )

  let $options := 
    <options xmlns="xdmp:http">
      <authentication method="basic">
        <username>{$username}</username>
        <password>{$password}</password>
      </authentication>
      <data>{$payload}</data>
      <headers>
        <content-type>application/x-www-form-urlencoded</content-type>
      </headers>
    </options>
  
  let $response := xdmp:http-post($api-endpoint,$options)
  
  return tw:handle-http-response($response)
};

(: 
  This will ensure that xml specific characters (<,&)
  don't cause XQuery to freak out during message generation
:)
declare function tw:clean(
  $text as xs:string
) as xs:string {
  fn:replace(
    fn:replace(
      $text,
      '<',
      '&lt;'
    ),
    '&#38;',
    '&amp;'
  )
};

(: 
  This function handles the twilio rest response.
  It keeps a list of success codes, and if it's not in
  that sequence, it will log and throw an error
:)
declare function tw:handle-http-response(
  $response as node()*
) as element(success) {
  let $success-codes := (200,201,202)
  return
    if(fn:index-of($success-codes,$response/http:code)) then (
      tw:handle-twilio-success($response[2]/node())
    ) else (
      let $_ := 
        if($logging) then (
          xdmp:log($response,'debug')
        ) else ()

      return 
        tw:twilio-error(
          $response[2]/node()
        )
    )
};

(:
  This function handles the success. It returns an xml node with 
  the api version from the server as well as the id of the
  text received. The API version should match the URI version:
     https://api.twilio.com/_______/... where _____ is the API version
:)
declare function tw:handle-twilio-success(
  $response as element(TwilioResponse)?
) as element(success) {
  <success>
    <value>True</value>
    <api-version>{$response/SMSMessage/ApiVersion/text()}</api-version>
    <sms-id>{$response/SMSMessage/Sid/text()}</sms-id>
  </success>
};

(:
  This function throws an error with the twilio code and message
:)
declare function tw:twilio-error(
  $response as element(TwilioResponse)?
) {
  if($error-level eq 1) then (
    tw:error(
      "ERROR-TW01",
      "Failed to send SMS",
      tw:value-or-default(
        $response/RestException/Status/text(),
        500
      ),
      tw:value-or-default(
        $response/RestException/Message/text(),
        "Twilio failed but did not return an error message."
      )
    )
  ) else (
    <success>
      <value>False</value>
      <message>{$response/RestException/Message/text()}</message>
    </success>
  )
};

declare function tw:value-or-default (
  $value,
  $default
) {
  if($value) then (
    $value
  ) else (
    $default
  )
};

declare function tw:error (
  $error-code as xs:string,
  $error-msg as xs:string,
  $response-code as xs:int,
  $response-msg as xs:string
) {
  fn:error(
    xs:QName($error-code), 
    $error-msg,
    (
      $response-code, 
      $response-msg
    )
  )
};
