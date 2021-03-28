{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Sensei.FlowAPISpec where

import Data.Function ((&))
import Data.Maybe (catMaybes)
import Data.Text.Encoding (encodeUtf8)
import Network.HTTP.Link (writeLinkHeader)
import Sensei.API
import Sensei.Builder
import Sensei.TestHelper
import Sensei.Time
import Test.Hspec

spec :: Spec
spec = withApp app $
  describe "Flows API" $ do
    it "POST /api/log with Flow body register start of a flow event" $ do
      postFlow anOtherFlow
        `shouldRespondWith` 200

    it "GET /api/flows/<user> retrieves all Flows ungrouped" $ do
      let flow1 = anOtherFlow
          flow2 = Flow (FlowType "Meeting") "arnaud" (UTCTime (succ aDay) 0) "some/directory"
      postFlow_ flow1
      postFlow_ flow2

      let expectedGroups =
            [ Leaf
                [ FlowView (LocalTime aDay oneAM) (LocalTime aDay sixThirtyPM) Other,
                  FlowView (LocalTime (succ aDay) oneAM) (LocalTime (succ aDay) oneAM) (FlowType "Meeting")
                ]
            ]

      getJSON "/api/flows/arnaud"
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals expectedGroups)

    it "GET /api/flows/<user>?group=Day retrieves all Flows grouped by Day" $ do
      let flow1 = anOtherFlow
          flow2 = Flow (FlowType "Meeting") "arnaud" (UTCTime (succ aDay) 0) "some/directory"
      postFlow_ flow1
      postFlow_ flow2

      let expectedGroups =
            [ GroupLevel
                Day
                (LocalTime aDay oneAM)
                (Leaf [FlowView (LocalTime aDay oneAM) (LocalTime aDay sixThirtyPM) Other]),
              GroupLevel
                Day
                (LocalTime (succ aDay) oneAM)
                (Leaf [FlowView (LocalTime (succ aDay) oneAM) (LocalTime (succ aDay) sixThirtyPM) (FlowType "Meeting")])
            ]

      getJSON "/api/flows/arnaud?group=Day"
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals expectedGroups)

    it "GET /api/flows/<user>/<day>/notes retrieves Notes for given day with link headers" $ do
      let flow1 = anOtherFlow
          flow2 = NoteFlow "arnaud" (UTCTime (succ aDay) 0) "some/directory" "some note"
          expectedNotes = [NoteView (LocalTime (succ aDay) oneAM) "some note"]

      postFlow_ flow1
      postNote_ flow2

      getJSON "/api/flows/arnaud/1995-10-11/notes"
        `shouldRespondWith` ResponseMatcher
          200
          [ "Link"
              <:> encodeUtf8
                ( writeLinkHeader $
                    catMaybes
                      [ nextDayLink "arnaud" (Just $ succ aDay),
                        previousDayLink "arnaud" (Just $ succ aDay)
                      ]
                )
          ]
          (jsonBodyEquals expectedNotes)

    it "GET /api/flows/<user>/<day>/commands retrieves commands run for given day" $ do
      let cmd1 = Trace "arnaud" (UTCTime aDay 0) "some/directory" "foo" ["bar"] 0 10
          cmd2 = Trace "arnaud" (UTCTime aDay 1000) "other/directory" "git" ["bar"] 0 100

          expected =
            [ CommandView (LocalTime aDay oneAM) "foo" 10,
              CommandView (LocalTime aDay (TimeOfDay 1 16 40)) "git" 100
            ]

      postTrace_ cmd1
      postTrace_ cmd2

      getJSON "/api/flows/arnaud/1995-10-10/commands"
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals expected)

    it "GET /api/flows/<user>/<day>/summary returns a summary of flows and traces for given day" $ do
      let flow1 = anOtherFlow
          flow2 = Flow (FlowType "Learning") "arnaud" (UTCTime aDay 1000) "some/directory"
          cmd1 = Trace "arnaud" (UTCTime aDay 0) "some/directory" "foo" ["bar"] 0 10
          cmd2 = Trace "arnaud" (UTCTime aDay 1000) "other/directory" "git" ["bar"] 0 100

      postFlow_ flow1
      postFlow_ flow2
      postTrace_ cmd1
      postTrace_ cmd2

      let expected =
            FlowSummary
              { summaryPeriod = (toEnum 50000, toEnum 50000),
                summaryFlows = [(FlowType "Learning", 0), (Other, 1000)],
                summaryCommands = [("foo", 10), ("git", 100)]
              }

      getJSON "/api/flows/arnaud/1995-10-10/summary"
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals expected)

    it "GET /api/flows/<user>/<month>/summary returns a summary of flows and traces for given month" $ do
      let flow1 = anOtherFlow
          flow2 = Flow (FlowType "Learning") "arnaud" (UTCTime aDay 1000) "some/directory"
          flow3 = flow2 & later 1 month
          cmd1 = Trace "arnaud" (UTCTime aDay 0) "some/directory" "foo" ["bar"] 0 10
          cmd2 = Trace "arnaud" (UTCTime aDay 1000) "other/directory" "git" ["bar"] 0 100

      postFlow_ flow1
      postFlow_ flow2
      postFlow_ flow3
      postTrace_ cmd1
      postTrace_ cmd2

      let expected =
            FlowSummary
              { summaryPeriod = (toEnum 50000, toEnum 50000),
                summaryFlows = [(FlowType "Learning", 0), (Other, 1000)],
                summaryCommands = [("foo", 10), ("git", 100)]
              }

      getJSON "/api/flows/arnaud/1995-10/summary"
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals expected)

    it "PATCH /api/flows/<user>/latest/timestamp updates latest flow's timestamp" $ do
      let flow1 = anOtherFlow
          flow2 = Flow Other "arnaud" (UTCTime aDay 1000) "some/directory"
          trace = Trace "arnaud" (UTCTime aDay 2000) "other/directory" "git" ["bar"] 0 100

      postFlow_ flow1
      postFlow_ flow2
      postTrace_ trace

      let expected = flow1 {_flowTimestamp = UTCTime aDay 400}
          timeshift :: TimeDifference = Minutes (-10)

      patchJSON "/api/flows/arnaud/latest/timestamp" timeshift
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals expected)

    it "GET /api/flows/<user>/latest retrieves latest flow" $ do
      let flow1 = anOtherFlow
          flow2 = Flow Other "arnaud" (UTCTime aDay 1000) "some/directory"

      postFlow_ flow1
      postFlow_ flow2

      getJSON "/api/flows/arnaud/latest"
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals flow2)

    it "GET /api/flows/<user>/2 retrieves flow 2 steps back" $ do
      let flow1 = anOtherFlow
          flow2 = anOtherFlow & later 1000 seconds
          flow3 = anOtherFlow & later 2000 seconds
      postFlow_ flow1
      postFlow_ flow2
      postFlow_ flow3

      getJSON "/api/flows/arnaud/2"
        `shouldRespondWith` ResponseMatcher 200 [] (jsonBodyEquals flow1)
