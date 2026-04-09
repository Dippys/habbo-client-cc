package com.sulake.habbo.utils
{
    public class BuildersClubTools 
    {
        private static const BUILDERS_CLUB_FURNITURE_ID_BASE:int = 0x7FFF0000;


        public static function isBuildersClubFurniture(k:int):Boolean
        {
            return k >= BUILDERS_CLUB_FURNITURE_ID_BASE;
        }
    }
}
