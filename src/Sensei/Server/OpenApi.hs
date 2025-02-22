{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Swagger-based documentation for `booking` API
module Sensei.Server.OpenApi (senseiSwagger) where

import Control.Lens
import Data.Swagger hiding (Reference)
import Data.Text (pack)
import Data.Time
import Preface.Codec (Base64, Encoded, Hex)
import Sensei.API as Sensei
import Sensei.Server.Auth (SerializedToken)
import Sensei.Version
import Servant.Swagger
import System.Exit

-- Orphan instances
-- TODO: provide better/more specific return types in the API
instance ToSchema ExitCode where
  declareNamedSchema proxy =
    genericDeclareNamedSchemaUnrestricted defaultSchemaOptions proxy

instance ToSchema TimeZone where
  declareNamedSchema _ = return $ NamedSchema (Just "TimeZone") $ mempty & type_ .~ Just SwaggerString

instance ToSchema FlowType where
  declareNamedSchema _ = return $ NamedSchema (Just "FlowType") $ mempty & type_ .~ Just SwaggerString

instance ToSchema Color where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "Color") $
        mempty
          & description .~ Just "An RGB color represented as an hexadecimal string"
          & type_ .~ Just SwaggerString

instance ToSchema TimeDifference where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "TimeDifference") $
        mempty
          & description .~ Just "A time difference, positive or negative, expressed as a number of seconds"
          & type_ .~ Just SwaggerNumber

instance ToParamSchema FlowType where
  toParamSchema _ =
    mempty
      & type_ ?~ SwaggerString
      & enum_ ?~ ["End", "Note", "Other", "<any string>"]

instance ToSchema EventView

instance ToSchema FlowView

instance ToSchema NoteView

instance ToSchema CommandView

instance ToSchema UserProfile

instance ToSchema FlowSummary

instance ToParamSchema Group

instance ToSchema Group

instance ToSchema Op where
  declareNamedSchema proxy =
    genericDeclareNamedSchemaUnrestricted defaultSchemaOptions proxy

instance ToSchema GoalOp

instance ToSchema Goals

instance ToSchema CurrentGoals

instance ToSchema Goal where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "Goal") $
        mempty
          & description .~ Just "A single goal"
          & type_ .~ Just SwaggerString

instance ToParamSchema Reference where
  toParamSchema _ =
    mempty
      & enum_ ?~ ["latest", "head", "<any natural number>"]
      & type_ .~ Just SwaggerString

instance ToSchema a => ToSchema (GroupViews a) where
  declareNamedSchema proxy =
    genericDeclareNamedSchemaUnrestricted defaultSchemaOptions proxy

instance ToSchema Versions

instance ToSchema Event

instance ToSchema Flow

instance ToSchema Trace

instance ToSchema NoteFlow

instance ToSchema SerializedToken where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "SerializedToken") $
        mempty
          & description
            ?~ "A JWT Token in its serialized form, eg. 3 sequneces of base64-encoded strings separated by dots \
               \ which contain JSON objects. See https://jwt.io/introduction for more details."
          & type_ ?~ SwaggerString

instance ToSchema (Encoded Base64) where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "Base64") $
        mempty
          & description
            ?~ "A base64-encoded bytestring."
          & type_ ?~ SwaggerString

instance ToSchema (Encoded Hex) where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "Hex") $
        mempty
          & description
            ?~ "A hex-encoded bytestring."
          & type_ ?~ SwaggerString

instance ToSchema Regex where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "Regex") $
        mempty
          & description
            ?~ "A regular expression."
          & type_ ?~ SwaggerString

instance ToSchema ProjectName where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "ProjectName") $
        mempty
          & description
            ?~ "A project name."
          & type_ ?~ SwaggerString

instance ToSchema UserName where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "UserName") $
        mempty
          & description
            ?~ "A user name."
          & type_ ?~ SwaggerString

instance ToParamSchema UserName where
  toParamSchema _ =
    mempty
      & type_ ?~ SwaggerString

instance ToSchema Sensei.Tag where
  declareNamedSchema _ =
    return $
      NamedSchema (Just "Tag") $
        mempty
          & description
            ?~ "An arbitrary tag"
          & type_ ?~ SwaggerString

senseiSwagger :: Swagger
senseiSwagger =
  toSwagger senseiAPI
    & info . title .~ "Sensei API"
    & info . version .~ pack (showVersion senseiVersion)
    & info . description ?~ "An API for storing and querying data about one's coding habits and patterns"
    & info . license ?~ ("All Rights Reserved")
