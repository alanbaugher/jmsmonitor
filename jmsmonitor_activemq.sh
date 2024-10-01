#!/usr/bin/perl
###################################################################
#  Name: jmsmonitor
#
#  Goal: Monitor the Wildfly JMS queue for growth on each node using perl as the 'config' service ID
#
#  Note: vApp & most OS have perl pre-installed
#        vApp Wildfly will require authentication
#
#  Step 1: Add management user to use jboss-cli.sh:
#     sudo /opt/CA/wildfly-idm/bin/add-user.sh -m -u jboss-admin -p Password01!
#
#  Step 2: Update $path, $user, $pwd as needed
#
#  Update for ActiveMQ JMS (Wildfly 15) ;  prior release was HornetQ
#
#  ANA, 2024
###################################################################
use strict;
use warnings;

my $path="/opt/CA/wildfly-idm";
my $user="jboss-admin";
my $pwd="Password01!";

my $interval=10;
my $host=`hostname`;
chomp $host;

# HornetQ
#my $msgQueue = "iam.im.jms.queue.com.netegrity.ims.msg.queue";
# ActiveMQ  (Wildfly 15 / IGA vApp r14.5)
my $msgQueue = "jms.queue.iam.im.jms.queue.com.netegrity.ims.msg.queue";
#my $msgQueue = "jms.queue.iam_imAnalyticsNotificationQueue";
#my $msgQueue = "jms.queue.iam.im.jms.queue.StatusNotificationsQueue";
#my $msgQueue = "jms.queue.iam.im.jms.queue.RuntimeStatusDetailQueue";
#my $msgQueue = "jms.queue.ExpiryQueue";
#my $msgQueue = "jms.queue.testQueue";
#my $msgQueue = "jms.queue.DLQ";


my $prevMessageCount = "";
my $prevMessagesAdded = "";

print "Monitoring JMS Queue [$host]: $msgQueue\n";
while(1){
        my $date=`date`;
        chomp $date;
        # w/o auth credentials
        #my $message = `$path/bin/jboss-cli.sh --connect  --command="/subsystem=messaging/hornetq-server=default/jms-queue=$msgQueue:read-resource(include-runtime=true)" | grep message`;
        # with auth credentials
        #my $message = `$path/bin/jboss-cli.sh --connect --user=$user --password=$pwd  --command="/subsystem=messaging/hornetq-server=default/jms-queue=$msgQueue:read-resource(include-runtime=true)" | grep message`;
        # ActiveMQ
        my $message = `$path/bin/jboss-cli.sh --connect --user=$user --password=$pwd  --command="/subsystem=messaging-activemq/server=default/runtime-queue=$msgQueue:read-resource(include-runtime=true)" | grep message`;
        my $curMessageCount = "";
        my $curMessagesAdded = "";
        if($message =~ /.*message-count. =.\s+(\d+)L.*/){
                $curMessageCount = $1;
        }
        if($message =~ /.*messages-added. =.\s+(\d+)L.*/){
                $curMessagesAdded = $1;
        }
        #print "[$date] Current Queue Msg Count: $curMessageCount, Added (since start): $curMessagesAdded\n";
        if($prevMessageCount !~ /^$/){
                my $t_delta = $curMessagesAdded - $prevMessagesAdded;
                my $interval_total_added = $prevMessageCount + $t_delta;
                my $interval_total_processed = $interval_total_added - $curMessageCount;
                print "[$date] [$host] Messages processed: $interval_total_processed of $interval_total_added [Cur:$curMessageCount, Total:$curMessagesAdded]\n";
        }
        #Assign Current to prev
        $prevMessageCount = $curMessageCount;
        $prevMessagesAdded = $curMessagesAdded;
        sleep $interval;
}
