//
//  RetentionPlan.swift
//  DriftCheck
//
//  Created by Chris Mays on 3/26/25.
//

public enum RetentionMode: Equatable {
    /**
     Checks that anchor and tethered objects are nil when the anchor leaves the heirarchy.
     if the anchor is never added to the heirarchy then the behavior will defer to onDealloc.
     - Parameter waitFrames: The number of frames that the reporter should wait before checking for deallocation. This is useful if you have operations that extend shortly after dismissal.
     */
    case onRemovalFromHierarchy(waitFrames: Int = 2)
    /**
     This option is useful for when an anchor object does not have a traditional lifecycle of being deallocated
     once it leaves the heirarchy. In this case the tethered objects will be checked for drift when the anchor is deallocated.
     */
    case onDealloc
    /**
     Tethered objects will not be checked if the anchor has opted out.
     */
    case optOut
}
