// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

contract Oracle{
    struct Observation{
      uint32 timestamp;
      int56 tickCumulative;
    }
    // t=0, tick = 100
    // t=10, tickCumulative = 100*10

    Observation[] public observations;

    function writeObservation(int24 currentTick) external{

         if (observations.length == 0) {
            observations.push(
                Observation({
                    timestamp: uint32(block.timestamp),
                    tickCumulative: 0
                })
            );
            return;
        }

        Observation memory last = observations[observations.length - 1 ];
        uint32 timeElapsed = uint32(block.timestamp)-last.timestamp;
        observations.push(Observation({
            timestamp:uint32(block.timestamp), tickCumulative:last.tickCumulative + int56(int24(currentTick))*(int56(uint56(timeElapsed)) )
        
        })
        );
    }

    function getObservation(uint32 secondsAgo) public view returns(Observation memory)
    {
        uint32 targetTime = uint32(block.timestamp) - secondsAgo;
        for(uint256 i=observations.length ; i>0;i--){
            if(targetTime>= observations[i-1].timestamp)
            return observations[i-1];
        }
        revert ("OBSERVATION_NOT_FOUND");
    }
    function consult(uint32 secondsAgo) external view returns(int24 avgTick){
        Observation memory past = getObservation(secondsAgo);
        Observation memory current = observations[observations.length - 1];
        int56 tickDelta= current.tickCumulative-past.tickCumulative;
        uint32 timeDelta= current.timestamp- past.timestamp;
        require(timeDelta > 0, "ZERO_TIME_DELTA");
        avgTick = int24( tickDelta / (int56(uint56(timeDelta)))
        );
    }
}