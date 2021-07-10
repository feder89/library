import { Component, OnChanges, OnInit, SimpleChanges, Input, Output, EventEmitter } from '@angular/core';
import { ConfirmationService } from 'primeng/api';

@Component({
  selector: 'app-delete-confirm-dialog',
  templateUrl: './delete-confirm-dialog.component.html',
  styleUrls: ['./delete-confirm-dialog.component.css']
})
export class DeleteConfirmDialogComponent implements OnInit, OnChanges {

  constructor(private confirmService: ConfirmationService) { }

  @Input() type: string;
  @Input() value: string;
  @Output() confirmation: EventEmitter<any> = new EventEmitter();

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['type'] && changes['type'].currentValue != null && changes['value'] && changes['value'].currentValue != null) {
      this.confirm(changes['type'].currentValue, changes['value'].currentValue);
    }
  }

  ngOnInit() {
  }

  private confirm(type: string, value: string) {
    this.confirmService.confirm({
        message: 'Confermi di voler cancellare l\'oggetto '+type+' '+value+'?',
        accept: () => {
            this.confirmation.emit(true);
        },
        reject: () =>{
          this.confirmation.emit(false);
        }
    });
}

}
