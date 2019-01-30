
data "template_file" "nginx_conf" {
  template = "${file(var.nginx_confg_file)}"

  vars {
    proxied_url = "${var.proxied_url}"
    my_domain = "${var.domain_prefix}${var.my_dns}"
  }
}

resource "aws_instance" "web" {



  depends_on = ["data.template_file.nginx_conf"]

  tags {
    Name = "${var.resource_prefix}-ec2"
    Team = "TEAM"
    Project = "PROJECT"
    GitRepo = ""
    LastModified = "${timestamp()}"
  }

  connection {
    user = "ubuntu"
    private_key = ""/*NEED THIS*/
  }

  instance_type = "t2.small"

  ami = "${var.aws_ami}"

  user_data = "hack to get it to rebuild every-time ${timestamp()}}"

  # The name of our SSH keypair we created above.
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${var.default_security_group_id}"]

  subnet_id = "${var.subnet_priv_2a}"

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/ && wget http://nginx.org/keys/nginx_signing.key",
      "sudo apt-key add nginx_signing.key",
      "sudo sh -c \"echo 'deb http://nginx.org/packages/mainline/ubuntu/ '$(lsb_release -cs)' nginx' > /etc/apt/sources.list.d/Nginx.list\"",
      "sudo apt-get -y update",
      "sudo apt-get -y --allow-unauthenticated install nginx"
    ]
  }

  # nginx config file
  provisioner "file" {
    content = "${data.template_file.nginx_conf.rendered}"
    destination = "/tmp/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo service nginx start",
      "sleep 15",#sleep for 15 seconds
      "cat /var/log/nginx/error.log"
    ]
  }

}


resource "aws_elb" "web" {

  depends_on = ["aws_instance.web"]

  name = "${var.resource_prefix}-elb"

  subnets         = [ "${var.subnet_priv_2a}", "${var.subnet_priv_2b}", "${var.subnet_priv_2c}" ]
  security_groups = ["${var.default_security_group_id}"]

  instances       = ["${aws_instance.web.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  internal = true

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${var.env == "dev"? "" : ""}"
  }

}


resource "aws_ami_from_instance" "my-ami" {
  depends_on = ["aws_instance.web", "aws_elb.web"]

  name = "${var.resource_prefix}-${uuid()}"
  source_instance_id = "${aws_instance.web.id}"

}

resource "aws_launch_configuration" "proxy-launch" {

  name_prefix = "${var.resource_prefix}-launch"

  depends_on = ["aws_ami_from_instance.proxy-ami"]

  image_id = "${aws_ami_from_instance.my-ami.id}"
  instance_type = "t2.medium"

  security_groups = ["${var.default_security_group_id}"]

  key_name = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "my-asg" {

  depends_on = ["aws_elb.web", "aws_launch_configuration.proxy-launch"]

  name = "${var.resource_prefix}-${uuid()}-asg"

  launch_configuration = "${aws_launch_configuration.proxy-launch.id}"

  availability_zones = [
    "us-west-2a", "us-west-2b", "us-west-2c"
  ]

  health_check_type         = "ELB"

  vpc_zone_identifier = ["${var.subnet_priv_2a}", "${var.subnet_priv_2b}", "${var.subnet_priv_2c}"]


  load_balancers = ["${aws_elb.web.name}"]
  max_size = 3
  desired_capacity = 2
  min_size = 1

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key = "Name"
      value = "${var.resource_prefix}-ec2"
      propagate_at_launch = true
    }]

}

resource "aws_route53_record" "my-dns" {

  depends_on = ["aws_elb.web"]

  zone_id = "${var.hosted_zone_id}"
  name    = "${var.domain_prefix}${var.my_dns}"
  type    = "A"

  alias {
    evaluate_target_health = false
    name = "${aws_elb.web.dns_name}"
    zone_id = "Z1H1FL5HABSF5" #elastic load balancer zone! hardcoded on purpose
  }
}