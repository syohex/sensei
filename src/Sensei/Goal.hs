{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TemplateHaskell #-}

module Sensei.Goal
  ( GoalOp (..),
    goalOp,
    goalUser,
    goalTimestamp,
    goalDir,
    Goals (..),
    makeGoals,
    Goal (..),
    Op,
    goal,
    pop,
    push,
    shift,
    done,
  )
where

import Control.Lens.TH (makeLenses)
import Data.Aeson (FromJSON, ToJSON)
import Data.String (IsString)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import Sensei.Graph
  ( Op,
    G(..),
    mkG,
    adjacencyList,
    done,
    goal,
    pop,
    push,
    shift,
  )

data GoalOp = GoalOp
  { _goalOp :: Op,
    -- TODO should really be a UserName
    _goalUser :: Text,
    _goalTimestamp :: UTCTime,
    _goalDir :: Text
  }
  deriving (Eq, Show, Generic, ToJSON, FromJSON)

makeLenses ''GoalOp

newtype Goal = Goal Text
  deriving stock (Eq, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | A representation of goals in the form of a directed graph.
data Goals = Goals {goalsGraph :: [(Goal, [Goal])]}
  deriving (Eq, Show, Generic, ToJSON, FromJSON)

makeGoals :: [GoalOp] -> Goals
makeGoals ops =
  let G{unG} = mkG $ map _goalOp ops
      toGoal (v, es) = (Goal v, map Goal es)
  in Goals $ map toGoal $ adjacencyList unG
