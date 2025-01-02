using System.Collections.Generic;
using System.Threading;
using System.IO;
using System;
using TrueGearSDK;
using System.Linq;


namespace MyTrueGear
{
    public class TrueGearMod
    {
        private static TrueGearPlayer _player = null;



        public TrueGearMod() 
        {
            _player = new TrueGearPlayer("223750","DCS World");
            _player.Start();
        }    


        public void Play(string Event)
        { 
            _player.SendPlay(Event);
        }


    }
}
