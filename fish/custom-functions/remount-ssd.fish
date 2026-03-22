function remount-ssd
    set SSD_PATH /mnt/external-ssd
    set CONTAINERS (pct list | awk 'NR>1 {print $1}')

    if test (count $CONTAINERS) -eq 0
        echo "⚠️  No running containers found."
        return
    end

    echo "🧩 Preparing to remount: $SSD_PATH"
    echo "───────────────────────────────────────"
    echo "Stopping containers that may be using it..."

    for cid in $CONTAINERS
        echo -n "  ⏹️  Stopping LXC $cid... "
        pct stop $cid >/dev/null 2>&1
        if test $status -eq 0
            echo "✅ done"
        else
            echo "⚠️  failed"
        end
    end

    echo ""
    echo "🔄 Unmounting and remounting $SSD_PATH..."
    umount $SSD_PATH 2>/dev/null
    mount -a
    if test $status -eq 0
        echo "✅ Remounted successfully."
    else
        echo "⚠️  Remount failed! Check mount options."
        return 1
    end

    echo ""
    echo "🚀 Restarting containers..."
    for cid in $CONTAINERS
        echo -n "  ▶️  Starting LXC $cid... "
        pct start $cid >/dev/null 2>&1
        if test $status -eq 0
            echo "✅ running"
        else
            echo "⚠️  failed"
        end
    end

    echo ""
    echo "✅ All done! External SSD remounted and containers restarted."
end
