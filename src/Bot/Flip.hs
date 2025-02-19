module Bot.Flip where

import Control.Applicative
import qualified Data.Map as M
import Data.Maybe
import qualified Data.Text as T
import Data.Tuple

-- https://github.com/doherty/Text-UpsideDown/blob/master/lib/Text/UpsideDown.pm
-- http://www.fileformat.info/convert/text/upside-down-map.htm
flipText :: T.Text -> T.Text
flipText =
  T.map (\x -> fromMaybe x (M.lookup x table1 <|> M.lookup x table2)) .
  T.reverse

separateVariable :: [(Char, Char)]
separateVariable =
  [ ('\x0021', '\x00A1')
  , ('\x0022', '\x201E')
  , ('\x0026', '\x214B')
  , ('\x0027', '\x002C')
  , ('\x0028', '\x0029')
  , ('\x002E', '\x02D9')
  , ('\x0033', '\x0190')
  , ('\x0034', '\x152D')
  , ('\x0036', '\x0039')
  , ('\x0037', '\x2C62')
  , ('\x003B', '\x061B')
  , ('\x003C', '\x003E')
  , ('\x003F', '\x00BF')
  , ('\x0041', '\x2200')
  , ('\x0042', '\x10412')
  , ('\x0043', '\x2183')
  , ('\x0044', '\x25D6')
  , ('\x0045', '\x018E')
  , ('\x0046', '\x2132')
  , ('\x0047', '\x2141')
  , ('\x004A', '\x017F')
  , ('\x004B', '\x22CA')
  , ('\x004C', '\x2142')
  , ('\x004D', '\x0057')
  , ('\x004E', '\x1D0E')
  , ('\x0050', '\x0500')
  , ('\x0051', '\x038C')
  , ('\x0052', '\x1D1A')
  , ('\x0054', '\x22A5')
  , ('\x0055', '\x2229')
  , ('\x0056', '\x1D27')
  , ('\x0059', '\x2144')
  , ('\x005B', '\x005D')
  , ('\x005F', '\x203E')
  , ('\x0061', '\x0250')
  , ('\x0062', '\x0071')
  , ('\x0063', '\x0254')
  , ('\x0064', '\x0070')
  , ('\x0065', '\x01DD')
  , ('\x0066', '\x025F')
  , ('\x0067', '\x0183')
  , ('\x0068', '\x0265')
  , ('\x0069', '\x0131')
  , ('\x006A', '\x027E')
  , ('\x006B', '\x029E')
  , ('\x006C', '\x0283')
  , ('\x006D', '\x026F')
  , ('\x006E', '\x0075')
  , ('\x0072', '\x0279')
  , ('\x0074', '\x0287')
  , ('\x0076', '\x028C')
  , ('\x0077', '\x028D')
  , ('\x0079', '\x028E')
  , ('\x007B', '\x007D')
  , ('\x203F', '\x2040')
  , ('\x2045', '\x2046')
  , ('\x2234', '\x2235')
  , ('╰', '╯')
  ]

table1 :: M.Map Char Char
table1 = M.fromList separateVariable

table2 :: M.Map Char Char
table2 = M.fromList $ map swap separateVariable
