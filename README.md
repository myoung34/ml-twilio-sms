ml-twilio-sms
=============

MarkLogic Twilio SMS Interface

Pre-requisites
-----

This module assumes you have a Twilio account. A free account is perfectly
reasonable, however the phone number to send the message to *must* be verified.

Usage
-----
    import module
      namespace twilio = "ml-twilio-sms:lib:twilio"
      at "/twilio.xqy";

    twilio:send-sms("9315550743","test")
