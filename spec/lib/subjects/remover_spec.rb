require 'spec_helper'

RSpec.describe Subjects::Remover do
  let(:workflow) { create(:workflow_with_subjects) }
  let(:subject_set) do
    create(:subject_set_with_subjects, workflows: [workflow])
  end
  let(:subjects) { subject_set.subjects }
  let(:subject) { subjects.sample }
  let(:remover) { Subjects::Remover.new(subject.id) }
  let(:talk_client) { instance_double(Panoptes::TalkClient) }
  let(:discussions) { [] }

  describe "#cleanup" do
    before do
      allow(talk_client)
        .to receive(:discussions)
        .with(focus_id: subject.id, focus_type: "Subject")
        .and_return(discussions)
      allow(remover).to receive(:talk_client).and_return(talk_client)
    end

    context "without a real subject" do
      let(:subject) { double(id: 100) }

      it "should ignore non existant subject ids" do
        expect(remover.cleanup).to be_falsey
      end
    end

    it "should not remove a subject that has been classified" do
      create(:classification, subjects: [subject])
      expect(remover.cleanup).to be_falsey
    end

    it "should not remove a subject that has been collected" do
      create(:collection, subjects: [subject])
      expect(remover.cleanup).to be_falsey
    end

    context "with a talk discussions" do
      let(:discussions) { [{"dummy" => "discussion"}] }

      it "should not remove a subject that has been in a talk discussion" do
        expect(remover.cleanup).to be_falsey
      end
    end

    it "should remove a subject that has not been used" do
      remover.cleanup
      expect { Subject.find(subject.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should remove the associated set_member_subjects" do
      sms_ids = subject.set_member_subjects.map(&:id)
      remover.cleanup
      expect { SetMemberSubject.find(sms_ids) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should remove the associated media resources" do
      locations = subjects.map { |s| create(:medium, linked: s) }
      media_ids = subject.reload.locations.map(&:id)
      remover.cleanup
      expect { Medium.find(media_ids) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "notify cellect about the subject removal" do
      expect(RetireCellectWorker)
        .to receive(:perform_async)
        .with(subject.id, workflow.id)
      remover.cleanup
    end
  end
end
